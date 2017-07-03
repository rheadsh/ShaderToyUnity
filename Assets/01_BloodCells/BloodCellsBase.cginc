//Reference shader created by kuvkar https://www.shadertoy.com/view/4ttXzj
//Translation and modification made by Roberto Cabezas H.


float smin( float a, float b, float k )
{
    float h = clamp( 0.5+0.5*(b-a)/k, 0.0, 1.0 );
    return lerp( b, a, h ) - k*h*(1.0-h);
}

float cells(float2 uv){  // Trimmed down.
    uv = lerp(sin(uv + float2(1.57, 0)), sin(uv.yx*1.4 + float2(1.57, 0)), .75);
    return uv.x*uv.y*.3 + .7;
}

const float BEAT = 4.0;
float fbm(float2 uv)
{
    float f = 200.0;
    float2 r = (float2(.9, .45));
    float2 tmp;
    float T = 100.0 + _Time.y * 1.3;
    T += sin(_Time.y * BEAT) * .1;

    // layers of cells with some scaling and rotation applied.
    for (int i = 1; i < 8; ++i)
    {
        float fi = float(i);
        uv.y -= T * .5;
        uv.x -= T * .4;
        tmp = uv;

        uv.x = tmp.x * r.x - tmp.y * r.y;
        uv.y = tmp.x * r.y + tmp.y * r.x;
        float m = cells(uv);
		m += sin((_Time.y + float(i)*1.3217)*3.52) * 0.05;
        f = smin(f, m, .07);
    }
    return 1. - f;
}

float3 g(float2 uv)
{
    float2 off = float2(0.0, .03);
    float t = fbm(uv);
    float x = t - fbm(uv + off.yx);
    float y = t - fbm(uv + off);
    float s = .0025;
    float3 xv = float3(s, x, 0);
    float3 yv = float3(0, y, s);
    return normalize(cross(xv, -yv)).xzy;
}

float3 ld = normalize(float3(1.0, 2.0, 3.));
