package br.com.smarthas.model;

import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.CsvSource;

import static org.assertj.core.api.Assertions.assertThat;

/** Mesmos casos de FN_CLASSIFICAR_LEITURA (limites inclusivos, limites nulos). */
class ReadingClassificationTest {

    @ParameterizedTest
    @CsvSource(nullValues = "null", value = {
            "29.99, 30,   35,   NORMAL",
            "30,    30,   35,   ALERTA",
            "34.99, 30,   35,   ALERTA",
            "35,    30,   35,   CRITICA",
            "500,   null, null, NORMAL",
            "90,    null, 90,   CRITICA",
            "-5,    30,   35,   NORMAL"
    })
    void classifiesAgainstThresholds(double value, Double alert, Double critical, ReadingClassification expected) {
        assertThat(ReadingClassification.of(value, alert, critical)).isEqualTo(expected);
    }
}
