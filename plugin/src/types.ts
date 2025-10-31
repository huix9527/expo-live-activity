import { ConfigPlugin } from '@expo/config-plugins'

interface ConfigPluginProps {
  enablePushNotifications?: boolean
  ios?: {
    groupIdentifier?: string
  }
}

export type LiveActivityConfigPlugin = ConfigPlugin<ConfigPluginProps | undefined>
