/*

	Smooth Voronoi Borders
	----------------------

    Producing round-looking Voronoi borders via some rudimentary alterations to the regular
    Voronoi formula. As an aside, the results are presented in a faux 3D style. Essentially,
	it's a 2D effect.

	Dr2 has been putting up some rounded Voronoi border examples lately, and Abje produced
	a really cool one using a very simple tweak.

	Dr2's variation is fast and nicely distributed,	and as such, translates well to a
	raymarching environment. Abje's tweak can be combined with either IQ or Tomk's line
	distance Voronoi examples to produce really good quality rounded borders - I intend to
	produce an example later that I hope does it justice.

	This is yet another variation that I put together ages ago. I've outlined the method in
	the Voronoi function - not that it needs much explaining. It does the job under the
	right circumstances and it's reasonably cheap and simple to implement. However, for
	robustness, I'd suggest using one of the aforementioned methods.

	By the way, all variations basically do the same thing, and rely on the idea of
	incorporating a smooth distance metric into a Voronoi-like formula, which IQ wrote about
	in his article on smooth Voronoi.

	On a side note, Fabrice Neyret incorporated a third order distance to produce a rounded
	border effect also, which I used for an example a while back.

	Anyway, just for fun, I like to make 3D looking effects using nothing more than 2D layers.
	In this case, I went for a vector layered kind of aesthetic. For all intents and purposes,
    this example is just a few layers strategically laced together. It's all trickery, so
	there's very little physics involved.

	Basically, I've taken a Voronoi sample, then smoothstepped it in various ways to produce
	the web-like look. I've also taken two extra nearby samples in opposite directions,
	then combined the differences to produce opposing gradients to give highlights, the red
	and blue environmental reflections, etc. There's an offset layer for fake shadowing,
	the function value is used for fake occusion... It's all fake, and pretty simple too. :)


    // Other examples:

    // Faster method, and more evenly distributed.
    Smoothed Voronoi Tunnel - Dr2
	https://www.shadertoy.com/view/4slfWl

	// I like this method, and would like to cover it at some stage.
	Round Voronoi - abje
	https://www.shadertoy.com/view/ldXBDs

	// Smooth Voronoi distance metrics. Not about round borders in particular, but it's
	// the idea from which everything is derived.
	Voronoise - Article, by IQ
	http://iquilezles.org/www/articles/voronoise/voronoise.htm

    // A 3rd order nodal approach - I used it in one of my examples a while back.
	2D trabeculum - FabriceNeyret2
	https://www.shadertoy.com/view/4dKSDV
*/
//Translation and modification made by Roberto Cabezas H.


// float2 to float2 hash.
float2 hash22(float2 p) {

    // Faster, but doesn't disperse things quite as nicely. However, when framerate
    // is an issue, and it often is, this is a good one to use. Basically, it's a tweaked
    // amalgamation I put together, based on a couple of other random algorithms I've
    // seen around... so use it with caution, because I make a tonne of mistakes. :)
    float n = sin(dot(p, float2(41, 289)));
    //return frac(float2(262144, 32768)*n);

    // Animated.
    p = frac(float2(262144, 32768)*n);
    // Note the ".333," insted of ".5" that you'd expect to see. When edging, it can open
    // up the cells ever so slightly for a more even spread. In fact, lower numbers work
    // even better, but then the random movement would become too restricted. Zero would
    // give you square cells.
    return sin( p*6.2831853 + _Time.y)*.333 + .333;
    //return sin( p*6.2831853 + _Time.y*2.)*(cos( p*6.2831853 + _Time.y*.5)*.3 + .5)*.45 + .5;

}

//smoothmin function by iq
float smin( float a, float b, float k )
{
    float h = clamp(.5 + .5*(b - a)/k, 0., 1.);
    return lerp(b, a, h) - k*h*(1. - h);
}


// 2D 2nd-order Voronoi: Obviously, this is just a rehash of IQ's original. I've tidied
// up those if-statements. Since there's less writing, it should go faster. That's how
// it works, right? :)
//
// This is exactly like a regular Voronoi function, with the exception of the smooth
// distance metrics.
float Voronoi(in float2 p){

    // Partitioning the grid into unit squares and determining the fracional position.
	float2 g = floor(p), o; p -= g;

    // "d.x" and "d.y" represent the closest and second closest distances
    // respectively, and "d.z" holds the distance comparison value.
	float3 d = 2; // 8., 2, 1.4, etc.

    // A 4x4 grid sample is required for the smooth minimum version.
	for(int j = -1; j <= 2; j++){
		for(int i = -1; i <= 2; i++){

			o = float2(i, j); // Grid reference.
             // Note the offset distance restriction in the hash function.
            o += hash22(g + o) - p; // Current position to offset point vector.

            // Distance metric. Unfortunately, the Euclidean distance needs
            // to be used for clean equidistant-looking cell border lines.
            // Having said that, there might be a way around it, but this isn't
            // a GPU intensive example, so I'm sure it'll be fine.
			d.z = length(o);

            // Up until this point, it's been a regular Voronoi example. The only
            // difference here is the the mild smooth minimum's to round things
            // off a bit. Replace with regular mimimum functions and it goes back
            // to a regular second order Voronoi example.
            d.y = max(d.x, smin(d.y, d.z, .4)); // Second closest point with smoothing factor.
            d.x = smin(d.x, d.z, .2); // Closest point with smoothing factor.

		}
	}

    // Return the regular second closest minus closest (F2 - F1) distance.
    return d.y - d.x;

}
