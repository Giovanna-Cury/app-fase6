package br.com.smarthas.model;

/**
 * Classificação de uma leitura frente aos limites do sensor.
 * Os valores são persistidos exatamente como no banco (CHECK em SHAS_LEITURA).
 */
public enum ReadingClassification {
    NORMAL,
    ALERTA,
    CRITICA;

    /**
     * Espelho Java de {@code FN_CLASSIFICAR_LEITURA}, usado apenas pelo perfil
     * sem Oracle (H2). No perfil {@code oracle} a regra roda no banco.
     */
    public static ReadingClassification of(double value, Double alertThreshold, Double criticalThreshold) {
        if (criticalThreshold != null && value >= criticalThreshold) {
            return CRITICA;
        }
        if (alertThreshold != null && value >= alertThreshold) {
            return ALERTA;
        }
        return NORMAL;
    }
}
