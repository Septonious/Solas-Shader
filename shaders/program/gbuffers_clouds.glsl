
#ifdef FSH

//Program//
void main() {
	discard;
	
    /* DRAWBUFFERS:0 */
	gl_FragData[0] = vec4(0.0);
}

#endif


#ifdef VSH

//Program//
void main() {

	gl_Position = ftransform();
}

#endif