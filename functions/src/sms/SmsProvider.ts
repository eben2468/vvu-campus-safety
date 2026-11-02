/**
 * Sends text messages (docs/ARCHITECTURE.md §5). The SMS gateway is still
 * to be chosen (DECISIONS.md O2), so code depends only on this interface;
 * a real provider is added beside ConsoleSmsProvider once one is picked,
 * with its API key in a Functions secret (`defineSecret`).
 */
export interface SmsProvider {
  /** [to] is an E.164 number, e.g. +233241234567. */
  send(to: string, text: string): Promise<void>;
}
