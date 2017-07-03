//Reference shader created by Virgill https://www.shadertoy.com/view/llK3Dy
//Translation and modification made by Roberto Cabezas H.

float bounce;

//signed box
float sdBox(float3 p, float3 b)
{
  float3 d = abs(p)-b;
  return min(max(d.x,max(d.y,d.z)),0.)+length(max(d,0.));
}

// rotation
void pR(inout float2 p, float a)
{
	p = cos(a)*p+sin(a)*float2(p.y,-p.x);
}

// 3D noise function (IQ)
float noise(float3 p)
{
	float3 ip = floor(p);
    p -= ip;
    float3 s = float3(7,157,113);
    float4 h = float4(0.,s.yz,s.y+s.z)+dot(ip,s);
    p = p*p*(3 - 2 * p);
    h = lerp(frac(sin(h)*43758.5),frac(sin(h+s.x)*43758.5),p.x);
    h.xy = lerp(h.xz,h.yw,p.y);
    return lerp(h.x,h.y,p.z);
}

float map(float3 p)
{
	p.z -= 1.0;
    p *= 0.9;
    pR(p.yz,bounce*1.+0.4*p.x);
    return sdBox(p+float3(0,sin(1.6*_Time.y),0),float3(20.0, 0.05, 1.2))-.4*noise(8.*p+3.*bounce);
}

//	normal calculation
float3 calcNormal(float3 pos)
{
    float eps = 0.0001;
	float d = map(pos);
	return normalize(float3(map(pos+float3(eps,0,0))-d,map(pos+float3(0,eps,0))-d,map(pos+float3(0,0,eps))-d));
}

// 	standard sphere tracing inside and outside
float castRayx(float3 ro, float3 rd)
{
    float function_sign = (map(ro)<0.)?-1.:1.;
    float precis = 0.0001;
    float h = precis*2.0;
    float t = 0.;
	for(int i=0; i<120; i++)
	{
        if(abs(h)<precis||t>12.)break;
		h=function_sign*map(ro+rd*t);
        t+=h;
	}
    return t;
}

// 	refraction
float refr(float3 pos, float3 lig, float3 dir, float3 nor, float angle, out float t2, out float3 nor2)
{
    float h = 0.0;
    t2 = 2.0;
	float3 dir2 = refract(dir,nor,angle);
 	for(int i=0; i<50; i++)
	{
		if(abs(h)>3.0) break;
		h = map(pos+dir2*t2);
		t2 -= h;
	}
    nor2 = calcNormal(pos+dir2*t2);
    return(.5*clamp(dot(-lig,nor2),0.,1.)+pow(max(dot(reflect(dir2,nor2),lig),0.),8.));
}

//	softshadow
float softshadow(float3 ro, float3 rd)
{
    float sh = 1.0;
    float t = 0.02;
    float h = 0.0;
    for(int i=0; i<22; i++)
	{
        if (t>20.0)continue;
        h = map(ro+rd*t);
        sh = min(sh,4.0*h/t);
        t += h;
    }
    return sh;
}
