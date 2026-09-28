// Modelos alinhados ao contrato da API (docs/API_CONTRACT.md).

export type Role = 'ADMIN' | 'OPERATOR';

export interface User {
  id: number;
  name: string;
  username: string;
  email: string;
  role: Role;
}

export interface LoginResponse {
  token: string;
  user: User;
}

export type SensorStatus = 'ONLINE' | 'WARNING' | 'OFFLINE';

export interface Sensor {
  id: number;
  name: string;
  type: string;
  status: SensorStatus;
  location: string;
  value: number;
  unit: string;
  latitude: number;
  longitude: number;
  updatedAt: string;
  alertThreshold: number | null;
  criticalThreshold: number | null;
  responsibleId: number | null;
  responsibleName: string | null;
}

export type Severity = 'LOW' | 'MEDIUM' | 'HIGH' | 'CRITICAL';

export type AlertOrigin = 'MANUAL' | 'AUTOMATICO';

export interface Alert {
  id: number;
  title: string;
  description: string;
  severity: Severity;
  location: string;
  createdAt: string;
  resolved: boolean;
  origin: AlertOrigin;
  sensorId: number | null;
  resolvedAt: string | null;
}

// Payload de criação de alerta (POST /alerts).
export interface CreateAlertPayload {
  title: string;
  description: string;
  location: string;
  severity: Severity;
}

export interface DashboardSummary {
  totalSensors: number;
  onlineSensors: number;
  offlineSensors: number;
  activeAlerts: number;
  warningSensors: number;
  criticalAlerts: number;
  readingsLast24h: number;
  dataEngine: DataEngine;
}

// ---------------------------------------------------------------------------
// Fase 6 — telemetria e rotinas PL/SQL
// ---------------------------------------------------------------------------

/** Quem executou a regra de negócio: procedures/functions Oracle ou o fallback JPA. */
export type DataEngine = 'ORACLE_PLSQL' | 'JPA';

export type ReadingClassification = 'NORMAL' | 'ALERTA' | 'CRITICA';

export interface SensorReading {
  id: number;
  value: number;
  classification: ReadingClassification;
  readAt: string;
}

/** Resposta de POST /sensors/{id}/readings (parâmetros OUT de PRC_REGISTRAR_LEITURA). */
export interface ReadingRegistration {
  readingId: number;
  sensorId: number;
  value: number;
  classification: ReadingClassification;
  alertId: number | null;
  engine: DataEngine;
}

/** FN_CALC_CONFORMIDADE, FN_CALC_INDICE_RISCO e FN_FORMATAR_LEITURA. */
export interface SensorIndicators {
  sensorId: number;
  conformity24h: number | null;
  conformity7d: number | null;
  riskIndex: number;
  formattedLastReading: string;
  engine: DataEngine;
}

export interface DailyReportRow {
  sensorId: number;
  sensorName: string;
  sensorType: string;
  unit: string;
  referenceDate: string;
  readings: number;
  alertReadings: number;
  criticalReadings: number;
  minValue: number | null;
  avgValue: number | null;
  maxValue: number | null;
  conformity: number | null;
  summary: string;
  generatedAt: string;
}

/** Linha do SYS_REFCURSOR de PRC_RESUMO_POR_RESPONSAVEL. */
export interface ResponsibleSummary {
  userId: number;
  name: string;
  role: Role;
  sensors: number;
  sensorsNeedingAttention: number;
  readings: number;
  criticalReadings: number;
  openAlerts: number;
  averageConformity: number | null;
}

export interface RoutineResult {
  routine: string;
  processed: number;
  engine: DataEngine;
  executedAt: string;
}

export interface ExecutionLog {
  id: number;
  routine: string;
  level: 'INFO' | 'WARN' | 'ERROR';
  message: string;
  loggedAt: string;
}
