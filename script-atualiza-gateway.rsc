:log info "Iniciando Script"
:delay 5s
:log info "Lendo novo Gateway"
:global newgw [/ip dhcp-client get [find interface="ether1 - Link1" ] gateway ]
:delay 5s
:log info "Lendo Gateway ativo"
:global activegw [/ip route get [:pick [/ip route find comment="Gateway Net"] 0] gateway ]
:delay 5s
:log info "comparando Gateway´s"
:if ($newgw != $activegw) do={
/ip route set [find comment="Gateway Net"] gateway=$newgw
}
:log info "Gateway Atualizado"