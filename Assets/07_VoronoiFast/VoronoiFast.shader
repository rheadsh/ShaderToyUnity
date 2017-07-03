// Created by David Bargo - davidbargo/2015
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
//Translation and modification made by Roberto Cabezas H.

Shader "Hidden/VoronoiFast"
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

			#define ANIMATE

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
				float2 q = i.vertex.xy / _ScreenParams.yy;
				q.x += 2.0;
				float2 p = 10.* q;
				//p = mul(float2x2(0.7071, -0.7071, 0.7071, 0.7071), p);
				p = mul(p, float2x2(0.7071, -0.7071, 0.7071, 0.7071));

				float2 pi = floor(p);
				float4 v = float4(pi.xy, pi.xy + 1.0);
				v -= 64.* floor(v * 0.015);
				v.xz = v.xz * 1.435 + 34.423;
				v.yw = v.yw * 2.349 + 183.37;
				v = v.xzxz * v.yyww;
				v *= v;

				 #ifdef ANIMATE
					v *= _Time.y * 0.000004 + 0.5;
					float4 vx = 0.25 * sin(frac(v * 0.00047) * 6.2831853);
					float4 vy = 0.25 * sin(frac(v * 0.00074) * 6.2831853);
				#else
					float4 vx = 0.5 * (step(0.0, frac(v * 0.00047) - 0.5) - 0.5);
					float4 vy = 0.5 * (step(0.0, frac(v * 0.00074) - 0.5) - 0.5);
				#endif

				float2 pf = p - pi;
				vx += float4(0., 1., 0., 1.) - pf.xxxx;
				vy += float4(0., 0., 1., 1.) - pf.yyyy;
				v = vx * vx + vy * vy;

				v.xy = min(v.xy, v.zw);
				float3 col = lerp(float3(0.0, 0.4, 0.9), float3(0.0, 0.95, 0.9), min(v.x, v.y));

				return fixed4(col, 1);
			}
			ENDCG
		}
	}
}
