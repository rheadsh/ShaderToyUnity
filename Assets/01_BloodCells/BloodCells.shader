Shader "Custom/BloodCells"
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
			#include "BloodCellsBase.cginc"

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
				float2 uv = i.vertex.xy / _ScreenParams.xy;
				float a = _ScreenParams.x / _ScreenParams.y;
				uv.y /= a;
				float2 ouv = uv;
				float B = sin(_Time.y * BEAT);
				uv = lerp(uv, uv * sin(B), 0.035);
				float2 _uv = uv * 25.;
				float f = fbm(_uv);

				//Base color
				float4 col = float4(f,f,f,f);
				col.rgb *= float3(1, 0.3 + B * 0.05, 0.1 + B * 0.05);

				float v = normalize(float3(uv, 1));
				float3 grad = g(_uv);

				//Spec
				float3 H = normalize(ld + v);
				float S = max(0, dot(grad, H));
				S = pow(S, 4) * 0.2;
				col.rgb += S * float3(0.4, 0.7, 0.7);

				//Rim
				float R = 1.0 - clamp(dot(grad, v), 0, 1);
				col.rgb = lerp(col.rgb, float3(0.8, 0.8, 1), smoothstep(-0.2, 3.3, R));
				
				return smoothstep(0, 1, col);
			}
			ENDCG
		}
	}
}
