//Reference shader created by Kali https://www.shadertoy.com/view/XlfGRj
//Translation and modification made by Roberto Cabezas H.

Shader "Hidden/StarNest"
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

			#define iterations 17
			#define formuparam 0.53

			#define volsteps 20
			#define stepsize 0.1

			#define zoom   0.800
			#define tile   0.850
			#define speed  0.010

			#define brightness 0.0015
			#define darkmatter 0.300
			#define distfading 0.730
			#define saturation 0.850

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
			float4 _Mouse;

			fixed4 frag (v2f i) : SV_Target
			{
				float2 uv = i.vertex.xy / _ScreenParams.xy - 0.5;
				uv.y *= _ScreenParams.y / _ScreenParams.x;
				
				#if UNITY_UV_STARTS_AT_TOP
				uv.y = 1.0 - uv.y;
				#endif
				
				float3 dir = float3(uv * zoom, 1);

				float a1 = 0.5 + _Mouse.x / _ScreenParams.x;
				float a2 = 0.8 + _Mouse.y / _ScreenParams.y;
				float2x2 rot1 = float2x2(cos(a1), sin(a1), -sin(a1), cos(a1));
				float2x2 rot2 = float2x2(cos(a2), sin(a2), -sin(a2), cos(a2));
				dir.xz = mul(dir.xz, rot1);
				dir.xy = mul(dir.xy, rot2);
				float3 from = float3(1, 5, 0.5);
				from += float3(_Time.y * speed * 2.0, _Time.y * speed + 0.25, -2.0);
				from.xz = mul(from.xz, rot1);
				from.xy = mul(from.xy, rot2);

				// volumetric rendering
				float s = 0.1;
				float fade = 1;
				float3 v = float3(0,0,0);
				for (int r = 0; r < volsteps; r++)
				{
					float3 p = from+s*dir*0.5;
					p = abs(float3(tile, tile, tile)-fmod(p, float3(tile*2.0, tile*2.0, tile*2.0)));
					float pa = 0.0;
					float a = 0.0;

					for (int i=0; i<iterations; i++)
					{
						p = abs(p)/dot(p,p)-formuparam;
						a += abs(length(p)-pa);
						pa = length(p);
					}

					float dm = max(0, darkmatter-a*a*0.001);
					a *= a*a;
					if (r>6) fade *= 1-dm;

					v += fade;
					v += float3(s, s*s, s*s*s*s)*a*brightness*fade;
					fade *= distfading;
					s += stepsize;
				}
				float lv = length(v);
				v = lerp(float3(lv,lv,lv), v, saturation);

				return fixed4(v *0.01, 1);
			}
			ENDCG
		}
	}
}
