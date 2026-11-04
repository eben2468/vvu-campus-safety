import { SmsProvider } from "./SmsProvider";

/** Development provider: logs each message instead of sending it. */
export class ConsoleSmsProvider implements SmsProvider {
  async send(to: string, text: string): Promise<void> {
    console.info("SMS (not sent: no gateway configured)", { to, text });
  }
}
