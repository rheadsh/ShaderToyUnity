Shader "Hidden/StranglerFig"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_Color1 ("Texture", 2D) = "white" {}
		_Color2 ("Color", 2D) = "white" {}
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
			#include "StranglerFigBase.cginc"

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
			sampler2D _Color1;
			sampler2D _Color2;

			fixed4 frag (v2f i) : SV_Target
			{
				float2 uv = (i.vertex.xy - 0.5 * _ScreenParams.xy) / _ScreenParams.y;

				float3 pos = float3(uv, 0.), ray = normalize(float3(uv, 0.5));

				int ri = 0;
				for (int i = 0; i < 50; ++i)
				{
					float dist = map(pos);
					if (dist < 0.001)
					{
						break;
					}
					pos += ray * dist;
					ri = i;
				}
				float ratio = float(ri) / 50;
				float4 color;
				color.rgb = lerp(wood1, wood2, infos.blend);

				float3 n = normal(pos);

				float3 tex = triplanar(pos, n, _Color2, .09);
				tex = lerp(tex, triplanar(pos, n, _Color1, 0.5), infos.blend);
				float lum = luminance(tex);
				color.rgb *= smoothstep(-.5, 1., lum) * 2.;
				color.rgb *= 1.- ratio;

				return fixed4(color.rgb, 1);
			}
			ENDCG
		}
	}
}
