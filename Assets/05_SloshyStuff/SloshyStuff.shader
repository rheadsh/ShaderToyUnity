Shader "Hidden/SloshyStuff"
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
			#include "SloshyStuffBase.cginc"

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
				uv = (uv * 2.0 - 1.0) * 0.5;
				uv.x *= _ScreenParams.x / _ScreenParams.y;

				//camera
				float3 rd = normalize(float3(uv, 2.));
				float3 ro = float3(0.0, 0.0, -6.5);

				return fixed4(marchScene(ro, rd), 1.0);
			}
			ENDCG
		}
	}
}
