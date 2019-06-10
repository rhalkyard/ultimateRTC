U2_CONTROL_STATUS   := $df1c ; Write: control register / Read: status register
U2_COMMAND_ID       := $df1d ; Write: command register / Read: ID register
U2_RESPONSE_DATA    := $df1e ; Read-only: data channel
U2_STATUS_DATA      := $df1f ; Read-only: status channel

U2_DEVICEID     = $c9

U2_PUSH         = (1 << 0)
U2_ACCEPT       = (1 << 1)
U2_ABORT        = (1 << 2)
U2_ERROR        = (1 << 3)

U2_STATEMASK    = ((1 << 4) | (1 << 5))
U2_STATE_IDLE   = 0
U2_STATE_BUSY   = (1 << 4)
U2_STATE_DLAST  = (1 << 5)
U2_STATE_DMORE  = ((1 << 4) | (1 << 5))

U2_STATUS_AVAIL = (1 << 6)
U2_DATA_AVAIL   = (1 << 7)
