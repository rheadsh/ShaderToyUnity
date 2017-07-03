Shader "Hidden/RhodiumLiquidCarbon"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
	}
	SubShader
	{
		// No culling or depth
		Cull Off ZWrite Off ZTest Always

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag

			#include "UnityCG.cginc"
			#include "RhodiumLiquidCarbonBase.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				float4 vertex : SV_POSITION;
			};

			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = v.uv;
				return o;
			}

			sampler2D _MainTex;

			fixed4 frag (v2f i) : SV_Target
			{
				bounce = abs(frac(0.05*_Time.y)-.5)*20.; // triangle function
				float2 uv = i.vertex.xy/_ScreenParams.xy;
				float2 p = uv * 2 - 1.;

				#if UNITY_UV_STARTS_AT_TOP
				p.y = 1 - p.y;
				#endif

				// bouncy cam every 10 seconds
				float wobble = (frac(0.1*(_Time.y-1.0))>=0.9)?frac(-_Time.y)*0.1*sin(30.0*_Time.y):0.0;

				// amera
				float3 dir = normalize(float3(2.0*i.vertex.xy -_ScreenParams.xy, _ScreenParams.y));
				float3 org = float3(0,2.*wobble,-3.0);

				// standard sphere tracing
				float3 color = float3(0.0,0.0,0.0);
				float3 color2 = float3(0.0,0.0,0.0);
				float t = castRayx(org,dir);
				float3 pos = org+dir*t;
				float3 nor = calcNormal(pos);

				// lighting
				float3 lig = normalize(float3(0.2,6.0,0.5));

				//scne depth
				float depth = clamp((1.0-0.09*t),0.0,1.0);

				float3 pos2 = float3(0.0,0.0,0.0);
				float3 nor2 = float3(0.0,0.0,0.0);

				if(t<12.0)
				{
					float cc = pow(max(dot(reflect(dir,nor),lig),0.0),16.0);
					color2 = float3(max(dot(lig,nor),0.)  +  float3(cc,cc,cc));
					color2 *= clamp(softshadow(pos,lig),0.0,1.0); //shadow
					float t2;
					color2.rgb += refr(pos,lig,dir,nor,0.9, t2, nor2)*depth;
					color2 -= clamp(0.1*t2,0.0,1.0);

				}

				float tmp = 0.;
				float T = 1.0;

				// animation of glow intensity
				float intensity = 0.1*-sin(0.209*_Time.y+1.0)+0.05;
				for(int i=0; i<128; i++)
				{
					float density = 0.0;
					float nebula = noise(org+abs(frac(0.05*_Time.y)-.5)*20.0);
					density = intensity-map(org+.5*nor2)*nebula;
					if(density > 0.0)
					{
						tmp = density / 128.;
						T *= 1. -tmp * 100.;
						if( T <= 0.) break;
					}
					org += dir*0.078;
				}
				float3 basecol=float3(1./1. ,  1./4. , 1./16.);
			    T=clamp(T,0.0,1.5);
			    color += basecol* exp(4.0*(0.5-T) - 0.8);
			    color2*=depth;
			    color2+= (1.0-depth)*noise(6.0*dir+0.3*_Time.y)*0.1;

				// scene depth included in alpha channel
			    return float4(float3(1.*color+0.8*color2)*1.3,abs(0.67-depth)*2.+4.*wobble);
			}
			ENDCG
		}
	}
}
