import { ConfigPlugin } from '@expo/config-plugins'

interface ConfigPluginProps {
  enablePushNotifications?: boolean
  groupIdentifier?: string
}

export type LiveActivityConfigPlugin = ConfigPlugin<ConfigPluginProps | undefined>
