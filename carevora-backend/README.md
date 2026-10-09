# CAREVORA — Emotional Wellness Monitoring Platform Backend

A Spring Boot 3.4 REST API backend powering the CAREVORA ecosystem for elderly emotional wellness monitoring and caregiver decision-support.

---

## 1. Technology Stack
- **Framework**: Java 21+ / Spring Boot 3.4.3
- **Security**: Spring Security + JWT Authentication + Role-Based Access (RESIDENT, CAREGIVER, ADMIN)
- **Persistence**: Spring Data JPA + Hibernate + Microsoft SQL Server / H2 in-memory driver
- **Documentation**: OpenAPI 3.0 / Swagger UI
- **AI/ML Layer**: Isolated `AiMlService` interface ready for Python FastAPI / RALPA trajectory prediction engine integration.

---

## 2. API Endpoints Overview

| Area | Method | Endpoint | Description |
|---|---|---|---|
| **Auth** | `POST` | `/api/auth/login` | JWT Login for Residents & Caregivers |
| **Residents** | `GET` | `/api/residents` | List all residents with search/filter |
| **Residents** | `GET` | `/api/residents/{id}` | Detailed resident wellness profile |
| **Assessments** | `POST` | `/api/assessments/submit` | Submit multimodal daily assessment |
| **Assessments** | `GET` | `/api/assessments/resident/{id}` | Get historical resident assessments |
| **Dashboard** | `GET` | `/api/dashboard/summary` | Aggregated metrics, risk distribution & trends |
| **Alerts** | `GET` | `/api/alerts` | Get real-time wellness alerts |
| **Alerts** | `PUT` | `/api/alerts/{id}/read` | Mark alert as acknowledged/read |
| **AI/ML Engine**| `GET` | `/api/ai/trajectory/{id}` | Forecasted RALPA progression & confidence |

---

## 3. Demo Credentials

| Role | Email | Password |
|---|---|---|
| **Caregiver (Dr. Eleanor Vance)** | `eleanor.vance@carevora.com` | `carevora_admin` |
| **Resident (Sarah Jenkins)** | `sarah.jenkins@carevora.com` | `carevora123` |
| **Resident (Arthur Pendelton)** | `arthur.p@carevora.com` | `carevora123` |

---

## 4. Swagger UI Documentation
When running the backend server locally:
```
http://localhost:8080/swagger-ui.html
```

---

## 5. Database Configuration (MS SQL Server)
In `src/main/resources/application.properties`, uncomment the SQL Server configuration lines:
```properties
spring.datasource.url=jdbc:sqlserver://localhost:1433;databaseName=carevora_db;encrypt=true;trustServerCertificate=true;
spring.datasource.username=sa
spring.datasource.password=YourStrong@Password
spring.datasource.driver-class-name=com.microsoft.sqlserver.jdbc.SQLServerDriver
```
