import numpy as np
import pandas as pd

DOMAINS = ["memory", "attention", "orientation", "recall", "reasoning"]
BASE_WEIGHTS = {"memory": .25, "attention": .20, "orientation": .20, "recall": .20, "reasoning": .15}


class ACRF:
    """Adaptive Cognitive Risk Fusion. Causal: each row uses only the same resident's current/earlier assessments."""

    def __init__(self, base_weights=None, lam=2.0, alpha=0.6, beta=0.5):
        self.base_weights = base_weights or BASE_WEIGHTS
        self.lam, self.alpha, self.beta = lam, alpha, beta

    def _core(self, df):
        rid = df["resident_id"]
        P, E, C = {}, {}, {}
        for d in DOMAINS:
            slow = ((df[f"{d}_response_time"] - self.rt_mean_[d]) / self.rt_std_[d]).clip(lower=0)
            P[d] = df[f"{d}_score"] - self.lam * slow
            E[d] = P[d].groupby(rid).transform(lambda s: s.ewm(alpha=self.alpha, adjust=False).mean())
            prior = E[d].groupby(rid).shift(1)
            C[d] = (P[d] - prior).fillna(0.0)
        return P, E, C

    def fit(self, df):
        self.rt_mean_ = {d: df[f"{d}_response_time"].mean() for d in DOMAINS}
        self.rt_std_ = {d: df[f"{d}_response_time"].std() for d in DOMAINS}
        _, _, C = self._core(df)
        self.change_sd_ = {d: max(C[d][C[d] != 0].std(), 1e-6) for d in DOMAINS}
        return self

    def transform(self, df):
        df = df.sort_values(["resident_id", "assessment_number"])
        P, E, C = self._core(df)
        raw_w = pd.DataFrame({d: self.base_weights[d] * (1 + self.beta * (-C[d] / self.change_sd_[d]).clip(lower=0))
                              for d in DOMAINS})
        w = raw_w.div(raw_w.sum(axis=1), axis=0)
        out = pd.DataFrame(index=df.index)
        for d in DOMAINS:
            out[f"acrf_base_{d}"] = E[d]
            out[f"acrf_change_{d}"] = C[d]
        out["acrf_level"] = sum(w[d] * E[d] for d in DOMAINS)
        out["acrf_change"] = sum(w[d] * C[d] for d in DOMAINS)
        out["acrf_n_declining"] = sum((C[d] < -self.change_sd_[d]).astype(int) for d in DOMAINS)
        out["acrf_weakest_domain"] = pd.concat([E[d] for d in DOMAINS], axis=1).min(axis=1)
        return out.loc[df.index].sort_index()
