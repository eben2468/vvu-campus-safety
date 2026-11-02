import { ConsoleSmsProvider } from "./ConsoleSmsProvider";
import { SmsProvider } from "./SmsProvider";

export { SmsProvider } from "./SmsProvider";

/** The provider in use. Swap in the real gateway here once chosen (O2). */
export function getSmsProvider(): SmsProvider {
  return new ConsoleSmsProvider();
}
