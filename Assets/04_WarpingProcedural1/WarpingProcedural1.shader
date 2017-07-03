Shader "Hidden/WarpingProcedural1"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_NoiseTex ("Noise Texture", 2D) = "white" {}
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
			#include "WarpingProcedural1Base.cginc"

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
				float2 of = float2(0, 0);

				float2 p = i.vertex.xy / _ScreenParams.xy;		
				float2 q = (-_ScreenParams.xy + 2.0 * (i.vertex.xy + of)) / _ScreenParams.y;

				float2 o, n;
				float f = func(q, o, n);
				float3 col = float3(0,0,0);

				col = lerp(float3(0.2, 0.1, 0.4), float3(0.3, 0.05, 0.05), f);
				col = lerp(col, float3(0.9, 0.9, 0.9), dot(n, n));
				col = lerp(col, float3(0.5, 0.2, 0.2), 0.5 * o.y * o.y);

				col = lerp(col, float3(0.0, 0.2, 0.4), 0.5 * smoothstep(1.2, 1.3, abs(n.y) + abs(n.x)));

				col *= f * 2.0;

				float ex = float2( 1.0 / _ScreenParams.x, 0.0 );
				float ey = float2( 0.0, 1.0 / _ScreenParams.y );
				float3 nor = normalize( float3( funcs(q+ex) - f, ex.x, funcs(q+ey) - f ) );

				float3 lig = normalize(float3(0.9, -0.2, -0.4));
				float dif = clamp(0.3 + 0.7 * dot(nor, lig), 0.0, 1.0);

				float3 bdrf;
				bdrf = float3(0.85, 0.90, 0.95) * (nor.y * 0.5 + 0.5);
				bdrf += float3(0.15, 0.10, 0.05) * dif;

				bdrf = float3(0.85, 0.90, 0.95) * (nor.y * 0.5 + 0.5);
				bdrf += float3(0.15, 0.10, 0.05) * dif;

				col *= bdrf;

				col = float3(1,1,1) - col;

				col = col * col;

				col *= float3(1.2, 1.25, 1.2);

				col *= 0.5 + 0.5 * sqrt(16.0 * p.x * p.y * (1.0 - p.x) * (1.0 - p.y));

				return fixed4(col, 1.0);
			}
			ENDCG
		}
	}
}
