// Created by inigo quilez - iq/2013
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
// See http://www.iquilezles.org/www/articles/warp/warp.htm for details
//Translation and modification made by Roberto Cabezas H.


uniform sampler2D _NoiseTex;

float2 hash2(float n)
{
	return frac(sin(float2(n, n + 1.0)) * float2(13.5453123, 31.1459123));
}

float noise(in float2 x)
{
	float2 p = floor(x);
	float2 f = frac(x);
	f = f * f * (3.0 - 2.0 * f);
	float a = tex2D(_NoiseTex, (p + float2(0.5, 0.5))/256.0).x;
    float b = tex2D(_NoiseTex, (p + float2(1.5, 0.5))/256.0).x;
    float c = tex2D(_NoiseTex, (p + float2(0.5, 1.5))/256.0).x;
    float d = tex2D(_NoiseTex, (p + float2(1.5, 1.5))/256.0).x;
	return lerp(lerp(a, b, f.x), lerp(c, d, f.x), f.y);
}

const float2x2 mtx = float2x2(0.80, 0.60, -0.60, 0.80);

float fbm4(float2 p)
{
	float f = 0.0;

	f += 0.5000 * (-1.0 + 2.0 * noise(p)); p = mul(mul(mtx, p), 2.02);
    f += 0.2500 * (-1.0 + 2.0 * noise(p)); p = mul(mul(mtx, p), 2.03);
    f += 0.1250 * (-1.0 + 2.0 * noise(p)); p = mul(mul(mtx, p), 2.01);
    f += 0.0625 * (-1.0 + 2.0 * noise(p));

    return f / 0.9375;
}

float fbm6(float2 p)
{
    float f = 0.0;

    f += 0.500000 * noise(p); p = mul(mul(mtx, p), 2.02);
    f += 0.250000 * noise(p); p = mul(mul(mtx, p), 2.03);
    f += 0.125000 * noise(p); p = mul(mul(mtx, p), 2.01);
    f += 0.062500 * noise(p); p = mul(mul(mtx, p), 2.04);
    f += 0.031250 * noise(p); p = mul(mul(mtx, p), 2.01);
    f += 0.015625 * noise(p);

    return f / 0.96875;
}

float func(float2 q, out float2 o, out float2 n)
{
    float ql = length(q);
    q.x += 0.05 * sin(0.11 * _Time.y * 1.333 + ql * 4.0);
    q.y += 0.05 * sin(0.13 * _Time.y * 1.333 + ql * 4.0);
    q *= 0.7 + 0.2 * cos(0.05 * _Time.y * 1.333);

    q = (q + 1.0) * 0.5;

    o.x = 0.5 + 0.5 * fbm4(float2(2.0 * q * float2(1.0, 1.0)));
    o.y = 0.5 + 0.5 * fbm4(float2(2.0 * q * float2(1.0, 1.0) + float2(5.2, 5.2)));

    float ol = length(o);
    o.x += 0.02 * sin(0.11 * _Time.y * 1.333 * ol) / ol;
    o.y += 0.02 * sin(0.13 * _Time.y * 1.333 * ol) / ol;


    n.x = fbm6(float2(4.0 * o * float2(1.0, 1.0) + float2(9.2, 9.2)));
    n.y = fbm6(float2(4.0 * o * float2(1.0, 1.0) + float2(5.7, 5.7)));

    float2 p = 4.0 * q + 4.0 * n;

    float f = 0.5 + 0.5 * fbm4(p);

    f = lerp(f, f * f * f * 3.5, f * abs(n.x));

    float g = 0.5 + 0.5 * sin(4.0 * p.x) * sin(4.0 * p.y);
    f *= 1.0 - 0.5 * pow(g, 8.0);

    return f;
}

float funcs( in float2 q)
{
    float2 t1, t2;
    return func(q, t1, t2);
}