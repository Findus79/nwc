; some defines for gamestates etc...

PLAYER_SPEED        = #511

ENEMY_STRIDE        = 15

; bullet flags
BULLET_IN_USE       = #%10000000
BULLET_EXPLODING    = #%01000000
BULLET_SPEED        = #700

ITEM_SPEED          = #384

; enemy flags
ENEMY_ALIVE         = #%10000000
ENEMY_WAITING       = #%01000000
ENEMY_SHOOT         = #%00100000
ENEMY_INIT          = #%11100000

ENEMY_EXPLODE       = #%00011111
ENEMY_REMOVE_SHOT   = #%11011111

UNSET_ENEMY_WAITING = #%10111111

; wave flags
WAVE_ALIVE          = #%00000001

; wave number stuff
WAVENUMBER_INIT     = #%00000001
WAVENUMBER_IN       = #%00000010
WAVENUMBER_HOLD     = #%00000100
WAVENUMBER_OUT      = #%00001000
WAVENUMBER_EXIT     = #%00010000


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