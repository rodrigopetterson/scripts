##########################
##
##   Atualize automaticamente o RouterOS e o Firmware
##   http://www.linksky.com.br
##
##   script by Rodrigo Petterson, rodrigo@linksky.com.br
##   Baseado em: https://github.com/massimo-filippi/mikrotik
##   created: 26-08-2023
##   updated: 
##   testado em: RouterOS 6.47.3 / varios dispositivos HW
##
##
##########  Definir variáveis
##
## O canal de atualização pode receber valores anteriores a 6.47.3: bugfix    | current | development | release-candidate
## O canal de atualização pode receber valores após 6.47.3:         long-term | stable  | development | testing

:local updChannel       "stable"

## Notificar via Telegram

:local notifyViaTelegram   true
:global TelegramIDgroup    "#log"

## Notificar por e-mail

:local notifyViaMail    true
:local email            "your@email.com"

########## Atualizar Firmware
##
## Vamos verificar se há firmware atualizado

:local rebootRequired false
/system routerboard

:if ( [get current-firmware] != [get upgrade-firmware]) do={

    ## Nova versão de firmware disponível, vamos atualizar
    ##
    ## Notificar via Log
    :log info ("Atualizando firmware da RB $[/system identity get name] de $[/system routerboard get current-firmware] para $[/system routerboard get upgrade-firmware]")
    
    ## Notificar via Telegram
    :if ($notifyViaTelegram) do={
       :global telegramMenssagem "Atualizando firmware da RB *$[/system identity get name]* de $[/system routerboard get current-firmware] para *$[/system routerboard get upgrade-firmware]*";
       :global teleMessageAttachements  "";
       /system script run "Message To Telegram";
   }
   
    ## Notificar via E-mail
    :if ($notifyViaMail) do={
       /tool e-mail send to="$email" subject="Atualizando firmware da RB $[/system identity get name]" body="Atualizando firmware da RB $[/system identity get name] de $[/system routerboard get current-firmware] para $[/system routerboard get upgrade-firmware]"
   }
   
    ## Upgrade (não será reinicializado, faremos isso mais tarde)
    upgrade
    :set rebootRequired true

}

########## Atualizar RouterOS

## Verifique atualizações
/system package update
set channel=$updChannel
check-for-updates
## Aguarde conexões lentas
:delay 15s;
## Nota importante: "versão instalada" era "versão atual" em sistemas operacionais Roter mais antigos
:if ([get installed-version] != [get latest-version]) do={
   ## Notify via Log
   :log info ("Upgrading RouterOS on router $[/system identity get name] from $[/system package update get installed-version] to $[/system package update get latest-version] (channel:$[/system package update get channel])")
   ## Notify via Slack
   :if ($notifyViaSlack) do={
       :global SlackMessage "Upgrading RouterOS on router *$[/system identity get name]* from $[/system package update get installed-version] to *$[/system package update get latest-version] (channel:$[/system package update get channel])*";
       :global SlackMessageAttachements  "";
       /system script run "Message To Slack";
   }

   ## Notify via E-mail
   :if ($notifyViaMail) do={
       /tool e-mail send to="$email" subject="Upgrading RouterOS on router $[/system identity get name]" body="Upgrading RouterOS on router $[/system identity get name] from $[/system package update get installed-version] to $[/system package update get latest-version] (channel:$[/system package update get channel])"
   }
   ## Wait for mail to be sent & upgrade
   :delay 15s;
   install
} else={
    :if ($rebootRequired) do={
        # Firmware was upgraded, but not RouterOS, so we need to reboot to finish firmware upgrade
        ## Notify via Slack
        :if ($notifyViaSlack) do={
            :global SlackMessage "Rebooting...";
            :global SlackMessageAttachements  "";
            /system script run "Message To Slack";
        }
        /system reboot
    } else={
        # No firmware nor RouterOS upgrade available, nothing to do, just log info
        :log info ("No firmware nor RouterOS upgrade found.")
        ## Notify via Slack
        :if ($notifyViaSlack) do={
            :global SlackMessage "No firmware nor RouterOS upgrade found.";
            :global SlackMessageAttachements  "";
            /system script run "Message To Slack";
        }
    }
}