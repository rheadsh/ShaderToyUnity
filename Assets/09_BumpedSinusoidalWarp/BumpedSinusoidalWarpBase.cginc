/*
	Bumped Sinusoidal Warp
	----------------------

	Sinusoidal planar deformation, or the 2D sine warp effect to people
	like me. The effect has been around for years, and there are
	countless examples on the net. IQ's "Sculpture III" is basically a
	much more sophisticated, spherical variation.

    This particular version was modified from Fabrice's "Plop 2," which in
	turn was a simplified version of Fantomas's "Plop." I simply reduced
	the frequency and iteration count in order to make it less busy.

	I also threw in a texture, added point-lit bump mapping, speckles...
	and that's pretty much it. As for why a metallic surface would be
	defying	the laws of physics and moving like this is anyone's guess. :)

	By the way, I have a 3D version, similar to this, that I'll put up at
	a later date.


	Related examples:

    Fantomas - Plop
    https://www.shadertoy.com/view/ltSSDV

    Fabrice - Plop 2
    https://www.shadertoy.com/view/MlSSDV

	IQ - Sculpture III (loosely related)
	https://www.shadertoy.com/view/XtjSDK

	Shane - Lit Sine Warp (far less code)
	https://www.shadertoy.com/view/Ml2XDV

*/


// Warp function. Variations have been around for years. This is
// almost the same as Fabrice's version:
// Fabrice - Plop 2
// https://www.shadertoy.com/view/MlSSDV

//Translation and modification made by Roberto Cabezas H.



float2 W(float2 p){

    p = (p+3.)*4.;

    float t = _Time.y/2.;

    // Layered, sinusoidal feedback, with time component.
    for (int i=0; i<3; i++){
        p += cos( p.yx*3. + float2(t,1.57))/3.;
        p += sin( p.yx + t + float2(1.57,0))/2.;
        p *= 1.3;
    }

    // A bit of jitter to counter the high frequency sections.
    p +=  frac(sin(p+float2(13, 7))*5e5)*.03-.015;

    return fmod(p,2.)-1.; // Range: [float2(-1), float2(1)]

}

// Bump mapping function. Put whatever you want here. In this case,
// we're returning the length of the sinusoidal warp function.
float bumpFunc(float2 p){

	return length(W(p))*.7071; // Range: [0, 1]

}

/*
// Standard ray-plane intersection.
float3 rayPlane(float3 p, float3 o, float3 n, float3 rd) {

    float dn = dot(rd, n);

    float s = 1e8;

    if (abs(dn) > 0.0001) {
        s = dot(p-o, n) / dn;
        s += float(s < 0.0) * 1e8;
    }

    return o + s*rd;
}
*/

float3 smoothFract(float3 x){ x = frac(x); return min(x, x*(1.-x)*12.); }
