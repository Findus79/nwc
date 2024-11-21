; some defines for gamestates etc...


STATE_PLAYING = %00000001
STATE_PAUSED  = %00000010

GS_TITLESCREEN = %00000001
GS_INGAME      = %00000010

; bullet flags
BULLET_IN_USE       = #%10000000
BULLET_EXPLODING    = #%01000000
BULLET_SPEED        = #2

; enemy flags
ENEMY_ALIVE         = #%10000000
ENEMY_EXPLODE       = #%01000000


PAD_B       = $8000
PAD_Y       = $4000
PAD_SELECT  = $2000
PAD_START   = $1000
PAD_UP      = $0800
PAD_DOWN    = $0400
PAD_LEFT    = $0200
PAD_RIGHT   = $0100
PAD_A       = $0080
PAD_X       = $0040
PAD_L       = $0020
PAD_R       = $0010