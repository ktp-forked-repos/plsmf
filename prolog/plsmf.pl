/*
 *  Prolog part of plsmf: standard MIDI file reading library
 *
 *  Copyright (C) 2009-2015 Samer Abdallah (Queen Mary University of London; UCL)
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 2 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 */
	  
:- module(plsmf,
	[	smf_new/1
   ,  smf_delete/1
   ,  smf_read/2		
   ,  smf_write/2
	,	smf_description/2
	,	smf_duration/2
	,	smf_duration/3
	,	smf_events/2
	,	smf_events/3
	,	smf_events/4
	,	smf_events_between/4
   ,  smf_add_events/2
   ,  smf_property/2
   ,  smf_tempo/3
	,	is_smf/1	
	]).
	
/** <module> Standard MIDI file reading

@author Samer Abdallah
*/

:-	use_foreign_library(foreign(plsmf)).


%% smf_read( +File:filename, -Ref:smf_blob) is semidet.
%
%  Attempts to read standard MIDI file named File and sets Ref
%  to an SMF blob atom which can be used to make further queries
%  about the file.

%% smf_duration( +Ref:smf_blob, +Timeline:oneof([metrical,physical]), -Dur:nonneg) is det.
%% smf_duration( +Ref:smf_blob, -Dur:nonneg) is det.
%
%  Returns the duration of the MIDI file in seconds (Timeline=physical) or
%  pulses (Timeline=metrica). smf_read/2 assumes physical timeline.
smf_duration(Ref,Dur) :- smf_duration(Ref,physical,Dur).

%% smf_description( +Ref:smf_blob, -Desc:atom) is det.
%
%  Sets Desc to an atom containing descriptive text about the
%  MIDI file, inluding the number of tracks and timing information.

%% smf_events( +Ref:smf_blob, -Events:list(smf_event)) is det.
%
%  Unifies Events with a list containing events in the MIDI file.
%  Not all types of events are handled, but most are. Events are
%  returned in a low-level numeric format containing the bytes
%  in the original MIDI data. The first argument of the smf
%  functor is always the time in seconds.
%
%  smf_event ---> smf( nonneg, byte)
%               ; smf( nonneg, byte, byte)
%               ; smf( nonneg, byte, byte, byte).
%
%  @see smf_events_between/4.
smf_events(Ref,Events) :- smf_events(Ref,physical,Events).
smf_events(Ref,Timeline,Events) :- smf_events(Ref,all,Timeline,Events).

smf_events(Ref,all,Timeline,Events) :- 
   timeline(Timeline),
   smf_events_without_track(Ref,0,Timeline,-1,-1,Events).
smf_events(Ref,track(T),Timeline,Events) :- 
   timeline(Timeline),
   smf_property(Ref,tracks(N)), between(1,N,T),
   smf_events_without_track(Ref,T,Timeline,-1,-1,Events).

%% smf_events_between( +Ref:smf_blob, +T1:nonneg, +T2:nonneg, -Events:list(smf_event)) is det.
%
%  Unifies Events with a list containing events in the MIDI file
%  between the given times T1 and T2. See smf_events/2 for more
%  information about the format of the events list.
smf_events_between(Ref,T1,T2,Events) :-
   smf_events_without_track(Ref,0,physical,T1,T2,Events).

%% is_smf(+Ref) is semidet.
%
%  Determines whether or not Ref is a MIDI file BLOB as returned
%  by smf_read/2.


smf_property(Ref,Prop) :-
   member(Key, [ppqn, fps, tracks, resolution]),
   Prop =.. [Key,Val],
   smf_info(Ref,Key,Val).

smf_tempo(Ref,seconds(T),Prop) :- smf_tempo(Ref,physical,T,Tempo), tempo_property(Tempo,Prop).
smf_tempo(Ref,pulses(T),Prop)  :- smf_tempo(Ref,metrical,T,Tempo), tempo_property(Tempo,Prop).

tempo_property(smf_tempo(T,_,_,_,_,_,_),time(metrical,T)).
tempo_property(smf_tempo(_,T,_,_,_,_,_),time(physical,T)).
tempo_property(smf_tempo(_,_,N,_,_,_,_),crochet_duration(D)) :- D is N rdiv 1000000.
tempo_property(smf_tempo(_,_,N,_,_,_,_),crochets_per_minute(D)) :- D is 60000000 rdiv N.
tempo_property(smf_tempo(_,_,_,N,D,_,_),time_signature(N/D)).

timeline(metrical).
timeline(physical).
/*
	MIDI derived event types:

	midi(O,T,msg(A,B,C)) :- midi_send(O,A,B,C,T).
	midi(O,T,noteon(Ch,NN,V)) :- midi_send(O,144+Ch,NN,V,T).
	midi(O,T,noteoff(Ch,NN)) :- midi_send(O,128+Ch,NN,0,T).
	midi(O,T,prog(Ch,Prog)) :- midi_send(O,192+Ch,Prog,Prog,T).
	midi(O,T,prog(Ch,Prog,Bank)) :-
		MSB is Bank // 128,
		LSB is Bank mod 128,
		midi_send(O,176+Ch,0,MSB,T),
		midi_send(O,176+Ch,32,LSB,T),
		midi(O,T,prog(Ch,Prog)).
*/
