package com.carevora.service;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.time.LocalDate;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.*;

class CognitiveScoringServiceTest {

    private CognitiveScoringService scoringService;
    private final LocalDate refDate = LocalDate.of(2026, 10, 16); // Friday, 2026

    @BeforeEach
    void setUp() {
        scoringService = new CognitiveScoringService();
    }

    @Test
    void testQ1_DayOfWeek() {
        // Correct
        assertEquals(1.0, scoringService.scoreQuestion(1, "Friday", refDate));
        assertEquals(1.0, scoringService.scoreQuestion(1, "Today is Friday!", refDate));
        assertEquals(1.0, scoringService.scoreQuestion(1, "it's friday morning", refDate));

        // Incorrect
        assertEquals(0.0, scoringService.scoreQuestion(1, "Monday", refDate));
        assertEquals(0.0, scoringService.scoreQuestion(1, "Saturday", refDate));

        // Missing / blank -> null
        assertNull(scoringService.scoreQuestion(1, null, refDate));
        assertNull(scoringService.scoreQuestion(1, "", refDate));
        assertNull(scoringService.scoreQuestion(1, "   ", refDate));
    }

    @Test
    void testQ2_Year() {
        // Correct
        assertEquals(1.0, scoringService.scoreQuestion(2, "2026", refDate));
        assertEquals(1.0, scoringService.scoreQuestion(2, "The year is 2026.", refDate));
        assertEquals(1.0, scoringService.scoreQuestion(2, "twenty twenty-six", refDate));

        // Incorrect
        assertEquals(0.0, scoringService.scoreQuestion(2, "2025", refDate));
        assertEquals(0.0, scoringService.scoreQuestion(2, "1999", refDate));

        // Missing
        assertNull(scoringService.scoreQuestion(2, null, refDate));
    }

    @Test
    void testQ3_Q4_Q7_MemoryQuestions_PartialAndDistinctWords() {
        // 3 distinct words: Sun, Book, Tree -> 1.0
        assertEquals(1.0, scoringService.scoreQuestion(3, "Sun, Book, Tree", refDate));
        assertEquals(1.0, scoringService.scoreQuestion(4, "Tree, sun and book", refDate));
        assertEquals(1.0, scoringService.scoreQuestion(7, "I remember book, sun, tree.", refDate));

        // 2 distinct words -> 0.5 (partial credit)
        assertEquals(0.5, scoringService.scoreQuestion(3, "Sun and Book", refDate));
        assertEquals(0.5, scoringService.scoreQuestion(7, "Tree, book", refDate));

        // 1 distinct word -> 0.5 (partial credit)
        assertEquals(0.5, scoringService.scoreQuestion(4, "Just Sun", refDate));

        // Duplicate word should NOT inflate count: "Sun, sun, sun" only counts 1 distinct word -> 0.5, not 1.0!
        assertEquals(0.5, scoringService.scoreQuestion(3, "Sun sun sun", refDate));
        assertEquals(0.5, scoringService.scoreQuestion(7, "Book book book", refDate));

        // 0 matching words -> 0.0
        assertEquals(0.0, scoringService.scoreQuestion(3, "Cat dog bird", refDate));

        // Missing -> null
        assertNull(scoringService.scoreQuestion(3, null, refDate));
    }

    @Test
    void testQ5_MathAddition() {
        // 2 + 3 = 5 or five
        assertEquals(1.0, scoringService.scoreQuestion(5, "5", refDate));
        assertEquals(1.0, scoringService.scoreQuestion(5, "five", refDate));
        assertEquals(1.0, scoringService.scoreQuestion(5, "It is 5.", refDate));
        assertEquals(1.0, scoringService.scoreQuestion(5, "That equals five", refDate));

        // Incorrect
        assertEquals(0.0, scoringService.scoreQuestion(5, "6", refDate));
        assertEquals(0.0, scoringService.scoreQuestion(5, "four", refDate));

        // Missing
        assertNull(scoringService.scoreQuestion(5, null, refDate));
    }

    @Test
    void testQ6_Comparison() {
        // Which is bigger: 3 or 8? -> 8 or eight
        assertEquals(1.0, scoringService.scoreQuestion(6, "8", refDate));
        assertEquals(1.0, scoringService.scoreQuestion(6, "eight", refDate));
        assertEquals(1.0, scoringService.scoreQuestion(6, "8 is bigger", refDate));
        assertEquals(1.0, scoringService.scoreQuestion(6, "Number eight", refDate));

        // Incorrect (e.g. 3)
        assertEquals(0.0, scoringService.scoreQuestion(6, "3", refDate));
        assertEquals(0.0, scoringService.scoreQuestion(6, "three", refDate));

        // Missing
        assertNull(scoringService.scoreQuestion(6, "   ", refDate));
    }

    @Test
    void testQ8_AffirmativeRecall() {
        // Did you hear the word Sun earlier?
        assertEquals(1.0, scoringService.scoreQuestion(8, "Yes", refDate));
        assertEquals(1.0, scoringService.scoreQuestion(8, "yeah I did", refDate));
        assertEquals(1.0, scoringService.scoreQuestion(8, "I heard sun", refDate));
        assertEquals(1.0, scoringService.scoreQuestion(8, "correct", refDate));

        // Negative / incorrect
        assertEquals(0.0, scoringService.scoreQuestion(8, "No", refDate));
        assertEquals(0.0, scoringService.scoreQuestion(8, "I did not", refDate));

        // Missing
        assertNull(scoringService.scoreQuestion(8, null, refDate));
    }

    @Test
    void testQ9_TimeTellingReasoning() {
        // Expected answers: clock, watch, wall clock, wristwatch, or other semantically equivalent answers
        assertEquals(1.0, scoringService.scoreQuestion(9, "clock", refDate));
        assertEquals(1.0, scoringService.scoreQuestion(9, "watch", refDate));
        assertEquals(1.0, scoringService.scoreQuestion(9, "wall clock", refDate));
        assertEquals(1.0, scoringService.scoreQuestion(9, "wristwatch", refDate));

        // Equivalent answers / variations
        assertEquals(1.0, scoringService.scoreQuestion(9, "A clock", refDate));
        assertEquals(1.0, scoringService.scoreQuestion(9, "smartwatch", refDate));
        assertEquals(1.0, scoringService.scoreQuestion(9, "pocketwatch", refDate));
        assertEquals(1.0, scoringService.scoreQuestion(9, "stopwatch", refDate));
        assertEquals(1.0, scoringService.scoreQuestion(9, "timepiece", refDate));
        assertEquals(1.0, scoringService.scoreQuestion(9, "chronometer", refDate));
        assertEquals(1.0, scoringService.scoreQuestion(9, "sundial", refDate));
        assertEquals(1.0, scoringService.scoreQuestion(9, "hourglass", refDate));
        assertEquals(1.0, scoringService.scoreQuestion(9, "clocks and watches", refDate));
        assertEquals(1.0, scoringService.scoreQuestion(9, "I use a watch to tell time", refDate));
        assertEquals(1.0, scoringService.scoreQuestion(9, "my wristwatch", refDate));
        assertEquals(1.0, scoringService.scoreQuestion(9, "The clock on the wall", refDate));

        // Case insensitivity and surrounding whitespace
        assertEquals(1.0, scoringService.scoreQuestion(9, "   CLOCK   ", refDate));
        assertEquals(1.0, scoringService.scoreQuestion(9, "  Watch.  ", refDate));
        assertEquals(1.0, scoringService.scoreQuestion(9, "WRISTWATCH", refDate));

        // Incorrect answers (other objects / non-time-telling items)
        assertEquals(0.0, scoringService.scoreQuestion(9, "Pen", refDate));
        assertEquals(0.0, scoringService.scoreQuestion(9, "Shoe", refDate));
        assertEquals(0.0, scoringService.scoreQuestion(9, "Bottle", refDate));
        assertEquals(0.0, scoringService.scoreQuestion(9, "calendar", refDate));
        assertEquals(0.0, scoringService.scoreQuestion(9, "ruler", refDate));
        assertEquals(0.0, scoringService.scoreQuestion(9, "thermometer", refDate));
        assertEquals(0.0, scoringService.scoreQuestion(9, "telephone", refDate));
        assertEquals(0.0, scoringService.scoreQuestion(9, "sunglasses", refDate));

        // Disallowed idioms / non-timekeeper phrases containing 'clock'
        assertEquals(0.0, scoringService.scoreQuestion(9, "biological clock", refDate));
        assertEquals(0.0, scoringService.scoreQuestion(9, "body clock", refDate));
        assertEquals(0.0, scoringService.scoreQuestion(9, "working around the clock", refDate));
        assertEquals(0.0, scoringService.scoreQuestion(9, "punch the clock", refDate));

        // Negations / inability to answer
        assertEquals(0.0, scoringService.scoreQuestion(9, "no clock", refDate));
        assertEquals(0.0, scoringService.scoreQuestion(9, "not a watch", refDate));
        assertEquals(0.0, scoringService.scoreQuestion(9, "without a clock", refDate));
        assertEquals(0.0, scoringService.scoreQuestion(9, "I do not use a clock", refDate));
        assertEquals(0.0, scoringService.scoreQuestion(9, "don't know", refDate));
        assertEquals(0.0, scoringService.scoreQuestion(9, "no idea", refDate));

        // Missing / empty / null
        assertNull(scoringService.scoreQuestion(9, null, refDate));
        assertNull(scoringService.scoreQuestion(9, "", refDate));
        assertNull(scoringService.scoreQuestion(9, "   ", refDate));
    }

    @Test
    void testQ10_CategoricalReasoning() {
        // Are an apple and an orange both fruits?
        assertEquals(1.0, scoringService.scoreQuestion(10, "Yes", refDate));
        assertEquals(1.0, scoringService.scoreQuestion(10, "both fruits", refDate));
        assertEquals(1.0, scoringService.scoreQuestion(10, "yes they are fruits", refDate));
        assertEquals(1.0, scoringService.scoreQuestion(10, "They are both fruit", refDate));

        // Incorrect
        assertEquals(0.0, scoringService.scoreQuestion(10, "No, vegetables", refDate));
        assertEquals(0.0, scoringService.scoreQuestion(10, "no", refDate));

        // Missing
        assertNull(scoringService.scoreQuestion(10, "", refDate));
    }

    @Test
    void testAutoScoreBattery_AllCorrect() {
        Map<Integer, String> responses = new HashMap<>();
        responses.put(1, "Friday");
        responses.put(2, "2026");
        responses.put(3, "Sun, Book, Tree");
        responses.put(4, "Sun, Book, Tree");
        responses.put(5, "5");
        responses.put(6, "8");
        responses.put(7, "Sun, Book, Tree");
        responses.put(8, "Yes");
        responses.put(9, "A clock");
        responses.put(10, "Yes, both are fruits");

        Map<Integer, Double> grades = scoringService.scoreBattery(responses, refDate);
        assertEquals(10, grades.size());
        for (int i = 1; i <= 10; i++) {
            assertEquals(1.0, grades.get(i), "Question " + i + " should be 1.0");
        }

        Map<String, Double> accuracies = scoringService.calculateDomainAccuracies(grades);
        assertEquals(1.0, accuracies.get("orientation"));
        assertEquals(1.0, accuracies.get("memory"));
        assertEquals(1.0, accuracies.get("attention"));
        assertEquals(1.0, accuracies.get("recall"));
        assertEquals(1.0, accuracies.get("reasoning"));

        Map<String, Double> domainScores = scoringService.calculateDomainScores(accuracies);
        assertEquals(100.0, domainScores.get("orientation"));
        assertEquals(100.0, domainScores.get("memory"));
        assertEquals(100.0, domainScores.get("attention"));
        assertEquals(100.0, domainScores.get("recall"));
        assertEquals(100.0, domainScores.get("reasoning"));

        double acrf = scoringService.calculateAcrfScore(domainScores);
        assertEquals(100.0, acrf, 0.001);
    }

    @Test
    void testAutoScoreBattery_WithMissingAnswers_DoesNotGradeZero() {
        Map<Integer, String> responses = new HashMap<>();
        responses.put(1, "Friday");
        responses.put(2, null); // missing
        responses.put(3, "Sun, Book"); // partial
        // 4 missing entirely

        assertFalse(scoringService.isAllQuestionsAnswered(responses));
        List<Integer> unanswered = scoringService.getUnansweredQuestionIds(responses);
        assertTrue(unanswered.contains(2));
        assertTrue(unanswered.contains(4));

        Map<Integer, Double> grades = scoringService.scoreBattery(responses, refDate);
        assertEquals(1.0, grades.get(1));
        assertNull(grades.get(2)); // must remain null, NOT 0.0
        assertEquals(0.5, grades.get(3));
        assertNull(grades.get(4)); // must remain null, NOT 0.0
    }
}
