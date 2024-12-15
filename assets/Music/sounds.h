//this file generated with SNES GSS tool

#define SOUND_EFFECTS_ALL	3

#define MUSIC_ALL	1

//sound effect aliases

enum {
	SFX_UNTITLED=0,
	SFX_UNTITLED=1,
	SFX_UNTITLED=2
};

//sound effect names

const char* const soundEffectsNames[SOUND_EFFECTS_ALL]={
	"UNTITLED",	//0
	"UNTITLED",	//1
	"UNTITLED"	//2
};

//music effect aliases

enum {
	MUS_UNTITLED=0
};

//music names

const char* const musicNames[MUSIC_ALL]={
	"UNTITLED"	//0
};

extern const unsigned char spc700_code_1[];
extern const unsigned char spc700_code_2[];
extern const unsigned char music_1_data[];

const unsigned char* const musicData[MUSIC_ALL]={
	music_1_data
};
