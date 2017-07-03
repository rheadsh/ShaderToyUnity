// Raymarching sketch about a plant named Strangler Fig that grows around a tree host.
// Recently saw in real life while traveling with friends in Thailand.
// Look for pictures on internet, it does really amazing shapes.
// Leon 21 / 06 / 2017
// using codes from iq, mercury, lj, koltes
//Translation and modification made by Roberto Cabezas H.

#define PI 3.14159
#define TAU 2.*PI
#define wood1 float3(0.658, 0.592, 0.529)
#define wood2 float3(0.415, 0.352, 0.290)
struct Infos { float3 color; float3 pos; float blend; };
Infos infos;
float2x2 rot(float a) { float c = cos(a), s = sin(a); return float2x2(c, -s, s, c); }
float sphere(float3 p, float r) { return length(p) - r; }
float cyl(float2 p, float r) { return length(p) - r; }
float iso(float3 p, float r) { return dot(p, normalize(sign(p))) - r; }

float smin(float a, float b, float r)
{
    float h = clamp(.5 + .5 * (b - a) / r, 0., 1.);
    return lerp(b, a, h) - r * h * (1.- h);
}

float scolor(float a, float b, float r)
{
    return clamp(.5 + .5 * (b - a) / r, 0., 1.);
}

float3 moda(float2 p, float count)
{
    float an = TAU / count;
    float a = atan2(p.x, p.y) + an * .5;
    float c = floor(a / an);
    a = fmod(a, an) - an * .5;
    c = lerp(c, abs(c), step(count * .5, abs(c)));
    return float3(float2(cos(a), sin(a)) * length(p), c);
}

// Martin Palko http://www.martinpalko.com/triplanar-mapping/
float3 triplanar(float3 pos, float3 normal, sampler2D channel, float uvscale)
{
    float2 uvx = pos.yz * uvscale;
    float2 uvy = pos.xz * uvscale;
    float2 uvz = pos.xy * uvscale;
    float3 texx = tex2D(channel, uvx).rgb;
    float3 texy = tex2D(channel, uvy).rgb;
    float3 texz = tex2D(channel, uvz).rgb;
    float3 blends = abs(normal);
    return texx * blends.x + texy * blends.y + texz * blends.z;
}

float map(float3 p);
float3 normal(float3 p)
{
    float e = .01;
    return normalize(float3(map(p + float3(e, 0, 0)) - map(p + float3(-e, 0, 0)),
                          map(p + float3(0, e, 0)) - map(p + float3(0, -e, 0)),
                          map(p + float3(0, 0, e)) - map(p + float3(0, 0, -e))));
}
float luminance(float3 c) { return (c.r + c.g + c.b) / 3.; }
float3 camera(float3 p)
{
    //p.xy = mul(rot(_Time.y * 0.3), p.xy);
    //p.xz = mul(rot(_Time.y * 0.3*1.5), p.xz);
    //p.yz *= rot((PI * /*(iMouse.y / iResolution.y - .5)*/ * step(0.5, iMouse.z)));
    //p.xz *= rot((PI * /*(iMouse.x / iResolution.x - .5)*/ * step(0.5, iMouse.z)));
    //p.xz *= rot(0.5);
    p.z += _Time.y * 0.3;
    return p;
}

float root(float3 p, float count, float torsade, float width, float scale)
{
    p.xz = mul(p.xz, rot(torsade));
    float3 p1 = moda(p.xz, count);
    p1.x -= width + .2 * sin(p1.z);
    p.xz = p1.xy;
    return cyl(p.xz, scale);
}

float map(float3 p)
{

    p = camera(p);
    float treespace = 8.;
    float treeindex = abs(floor(p.x / treespace) + floor(p.z / treespace));
    p.xz = fmod(p.xz, treespace) - treespace * 0.5;

    float blendRoots = .2;
    float blendTrunk = .02;
    float trunkWidth = 1.+ .25 * (.5 + .5 * sin(-p.y * .5 + _Time.y * 0.3 * 2.+ treeindex * 3.));
    float hostTrunk = cyl(p.xz, trunkWidth);

    // fat
    float seed1 = treeindex * 4.+ _Time.y * 0.3 + p.y * .25 + sin(p.y * .2 + _Time.y * 0.3);
    float seed2 = treeindex * 3.+ _Time.y * 0.3 + p.y * -.1 + sin(p.y * .2 + _Time.y * 0.3);
    float roots = root(p, 2.+ fmod(treeindex, 6.), seed1, trunkWidth, .2);
    roots = smin(roots, root(p, 2.+ fmod(treeindex, 6.), seed2, trunkWidth + .1 + sin(p.y * .3 + _Time.y * 0.3 * 3.+ treeindex) * .3, .3), blendRoots);
    // middle
    float seed3 = treeindex * 2.+ 3.* p.y * -.1 + sin(-p.y * .2 + _Time.y * 0.3 * 2.);
    float seed3b = treeindex * 2.+ .1 * p.y + sin(-p.y * .2 + _Time.y * 0.3 * 2.);
    roots = smin(roots, root(p, 3., seed3, trunkWidth + .1, .2), blendRoots);
    roots = smin(roots, root(p, 6.+ fmod(treeindex, 6.), seed3b, trunkWidth + .1, .2), blendRoots);
    // thin
    float seed4 = treeindex * 8.+ p.y * .5 + sin(p.y * 2.5 + _Time.y * 0.3 * 3.) * .2;
    float seed5 = treeindex * 4.+ p.y * -.5 + sin(p.y * 1.5 + _Time.y * 0.3 * 5.) * .2;
    roots = smin(roots, root(p, 8., seed4, trunkWidth + .1, .09), blendRoots);
    roots = smin(roots, root(p, 6., seed5, trunkWidth + .2, .08), blendRoots);

    float scene = smin(roots, hostTrunk, blendTrunk);
    infos.pos = p;
    infos.blend = scolor(hostTrunk, roots, blendTrunk);
    return scene;
}
