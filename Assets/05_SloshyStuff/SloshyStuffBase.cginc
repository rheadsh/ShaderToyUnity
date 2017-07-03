// Created by SHAU - 2017
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.


/**
 * I done this quite some time back so I ca't remember where I borrowed code from but will be from the
 * usual suspects. IQ, Shane, Fabrice, Dila et al
 **/

//Translation and modification made by Roberto Cabezas H.

#define EPS 0.005
#define FAR 10.0
#define PI 3.1415

int id = 0;

uniform sampler2D _NoiseTex;

float2x2 rot(float x)
{
	return float2x2(cos(x), sin(x), -sin(x), cos(x));
}

/* Distance Functions IQ */


// noise from iq's hell shader
float noise(in float3 x)
{
    float3 p = floor(x);
    float3 f = frac(x);
    f = f * f * (3.0 - 2.0 * f);
    float2 uv = (p.xy + float2(37.0, 17.0) * p.z) + f.xy;
    float2 rg = tex2D(_NoiseTex, (uv + .5) / 256.0).yx;
    return lerp(rg.x, rg.y, f.z) - 0.5;
}

float sdBox(float3 p, float3 pos, float3 size)
{
    float box = max(max(abs(p.x - pos.x) - size.x,
                abs(p.y - pos.y) - size.y),
                abs(p.z - pos.z) - size.z);
    return box;
}

float sdCapsule(float3 p, float3 a, float3 b, float3 cs, float r)
{
    p += cs;
    float3 pa = p - a, ba = b - a;
    float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
    return length(pa - ba * h) - r;
}

//frame made of 12 capsules
float dfFrame(float3 rp)
{
    float msd = 9999.0;
    float r = 0.1;
    float c1 = sdCapsule(rp,
                         float3(0.0, 1.0, 0.0),
                         float3(0.0, -1.0, 0.0),
                         float3(1.0, 0.0, 1.0),
                         r);
    msd = min(msd, c1);
    float c2 = sdCapsule(rp.zxy,
                         float3(0.0, 1.0, 0.0),
                         float3(0.0, -1.0, 0.0),
                         float3(1.0, 0.0, 1.0),
                         r);
    msd = min(msd, c2);
    float c3 = sdCapsule(rp,
                         float3(0.0, 1.0, 0.0),
                         float3(0.0, -1.0, 0.0),
                         float3(-1.0, 0.0, 1.0),
                         r);
    msd = min(msd, c3);
    float c4 = sdCapsule(rp.zxy,
                         float3(0.0, 1.0, 0.0),
                         float3(0.0, -1.0, 0.0),
                         float3(1.0, 0.0, -1.0),
                         r);
    msd = min(msd, c4);
    float c5 = sdCapsule(rp,
                         float3(0.0, 1.0, 0.0),
                         float3(0.0, -1.0, 0.0),
                         float3(1.0, 0.0, -1.0),
                         r);
    msd = min(msd, c5);
    float c6 = sdCapsule(rp.zxy,
                         float3(0.0, 1.0, 0.0),
                         float3(0.0, -1.0, 0.0),
                         float3(-1.0, 0.0, 1.0),
                         r);
    msd = min(msd, c6);
    float c7 = sdCapsule(rp,
                         float3(0.0, 1.0, 0.0),
                         float3(0.0, -1.0, 0.0),
                         float3(-1.0, 0.0, -1.0),
                         r);
    msd = min(msd, c7);
    float c8 = sdCapsule(rp.zxy,
                         float3(0.0, 1.0, 0.0),
                         float3(0.0, -1.0, 0.0),
                         float3(-1.0, 0.0, -1.0),
                         r);
    msd = min(msd, c8);
    float c9 = sdCapsule(rp.yzx,
                         float3(0.0, 1.0, 0.0),
                         float3(0.0, -1.0, 0.0),
                         float3(1.0, 0.0, 1.0),
                         r);
    msd = min(msd, c9);
    float c10 = sdCapsule(rp.yzx,
                         float3(0.0, 1.0, 0.0),
                         float3(0.0, -1.0, 0.0),
                         float3(-1.0, 0.0, 1.0),
                         r);
    msd = min(msd, c10);
    float c11 = sdCapsule(rp.yzx,
                         float3(0.0, 1.0, 0.0),
                         float3(0.0, -1.0, 0.0),
                         float3(1.0, 0.0, -1.0),
                         r);
    msd = min(msd, c11);
    float c12 = sdCapsule(rp.yzx,
                         float3(0.0, 1.0, 0.0),
                         float3(0.0, -1.0, 0.0),
                         float3(-1.0, 0.0, -1.0),
                         r);
    msd = min(msd, c12);
    if (msd < EPS) id = 1;
    return msd;
}

float dfScene(float3 rp)
{
    rp.xz = mul(rot(_Time.y), rp.xz);
    rp.xy = mul(rot(_Time.y), rp.xy);
    float b = sdBox(rp, float3(0,0,0), float3(1,1,1));
    return min(b, dfFrame(rp));
}

float dfSmoke(float3 rp)
{
    float b = sdBox(rp, float3(0,0,0), float3(1,1,1));
    float3 uv = rp + float3(_Time.y * 0.2, _Time.y * 0.35, 0.0);
    float n = noise(uv * 20.0) - 0.5;
    return b + n;
}

float3 surfaceNormal(float3 p)
{
    float2 e = float2(5.0 / _ScreenParams.y, 0);
    float d1 = dfScene(p + e.xyy), d2 = dfScene(p - e.xyy);
    float d3 = dfScene(p + e.yxy), d4 = dfScene(p - e.yxy);
    float d5 = dfScene(p + e.yyx), d6 = dfScene(p - e.yyx);
    float d = dfScene(p) * 2.0;
    return normalize(float3(d1 - d2, d3 - d4, d5 - d6));
}

/* Colouring in stuff. Slowly getting it */

//Shane - hue rotation. I think I've used this in pretty much all of my shaders so far :)
float3 rotHue(float3 p, float a)
{
    float2 cs = sin(float2(1.570796, 0) + a);
    float3x3 hr = float3x3(0.299, 0.587, 0.114, 0.299, 0.587, 0.114, 0.299, 0.587, 0.114) +

        float3x3(0.701, -0.587, -0.114, -0.299, 0.413, -0.114, -0.300, -0.588, 0.886) * cs.x +
              float3x3(0.168, 0.330, -0.497, -0.328, 0.035, 0.292, 1.250, -1.050, -0.203) * cs.y;
    return clamp(mul(hr, p), 0., 1.);
}


//volumetric march on frame interior
float3 vMarch2(float3 rp, float3 rd, float3 lc)
{
    float3 pc = float3(0,0,0);
    float d = 0.0;
    for (int i = 0; i < 40; i++)
    {
        rp = rp + rd * d;
        float ns = dfSmoke(rp);
        d += min(0.125, ns);
        float g = length(rp);
        pc += lc / exp(g * g) * 0.40;
        if (d > 2.0) break;
    }
    return pc;
}

//main march
float3 marchScene(float3 ro, float3 rd)
{

    float3 pc = float3(0,0,0); //returned pixel colour
    float d = 0.0; //distance marched
    float3 rp = float3(0,0,0); //ray position

    float3 lp = normalize(float3(2.0, 5.0, -3.0)); //light position
    float3 sc = rotHue(float3(0.5, 0.2, 0.8), fmod(_Time.y / 16.0, 6.283)); //scene colour

    for (int i = 0; i < 50; i++)
    {
        rp = ro + rd * d;
        float ns = dfScene(rp);
        d += ns;
        if (ns < EPS || d > FAR) break;
    }

    if (d < FAR)
    {

        if (id == 0)
        {
            pc = vMarch2(rp, rd, sc);
        }
        else
        {
            //hit scene
            float3 n = surfaceNormal(rp);
            float spe = pow(max(dot(reflect(rd, n), lp), 0.), 16.); // specular.
            pc += spe * float3(1,1,1);
        }
    }

    return pc;
}