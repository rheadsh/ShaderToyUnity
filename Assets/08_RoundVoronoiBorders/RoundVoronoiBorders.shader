Shader "Hidden/RoundVoronoiBorders"
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
			#include "RoundVoronoiBordersBase.cginc"

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
				// Screen coordinates.
				float2 uv = (i.vertex.xy - _ScreenParams.xy*.5)/ _ScreenParams.y;
			    //
			    // Mild, simplistic fisheye effect.
			    uv *= (.9 + length(uv)*.2);
			    //
			    // Scrolling action.
			    uv -= _Time.y *float2(1, .25)/8.;


			    // The function samples: Six 4x4 grid Voronoi function calls. That amount of work would
			    // break an old computer, but it's nothing for any reasonably modern GPU.
			    //
			    // Base function value.
			    float c = Voronoi(uv*5.);
			    // Nearby samples to the bottom right and bottom left.
			    float c2 = Voronoi(uv*5. - .002);
			    float c3 = Voronoi(uv*5. + .002);
			    // A more distant sample - used to fake a shadow and highlight.
			    float c4 = Voronoi(uv*5. + float2(.7, 1)*.2);
			    // Slight warped finer detailed (higher frequency) samples.
			    float c15 = Voronoi(uv*15. + c);
			    float c45 = Voronoi(uv*45. + c*2.);


			    // Shading the Voronoi pattern.
			    //
			    // Base shading and a mild spotty pattern.
				float v = (c*c)*(.9 + (c15 - smoothstep(.2, .3, c15))*.2);
			    float3 col = v;
			    //
			    // Mixing in some finer cloudy detail.
			    float sv = c15*.66 + (1. - c45)*.34; // Finer overlay pattern.
			    col = col*.8 + sv*sqrt(sv)*.4; // Mix in a little of the overlay.


			    // Simple pixelated grid overlay for a mild pixelated effect.
			    float2 sl = fmod(i.vertex, 2.);
			    //
			    // It looks more complicated than it is. Mildly darken every second vertical
			    // and horizontal pixel, and mildly lighten the others.
			    col *= 4.*(1. + step(1., sl.x))*(1. + step(1., sl.y))/9.;


			    // Adding a red highlight to the bottom left and a blue highlight to the top right. The
			    // end result is raised bubbles with environmental reflections. All fake, of course...
			    // Having said that, there is a little directional derivative science behind it.
			    float b1 = max((c2 - c)/.002, 0.); // Gradient (or bump) factor 1.
			    float b2 = max((c3 - c)/.002, 0.); // Gradient (or bump) factor 2.
			    //
			    // A touch of deep red and blue, with a bit of extra specularity.
			    col += float3(1, .0, .0)*b2*b2*b2*.15 + float3(0, .0, 1)*b1*b1*b1*.15;
			    //
			    // Slightly more mild orange and torquoise with less specularity.
			    col += float3(1, .7, .4)*b2*b2*.3 + float3(.4, .6, 1)*b1*b1*.3;

			    // Distant sampled overlay for a shadowy highlight effect. Made up. There'd be better ways.
			    float bord2 = smoothstep(0., fwidth(c4)*3., c4 - .1);
			    col = max(col + (1.-bord2)*.25, 0.);

			    // The web-like overlay. Tweaked to look a certain way.
			    float bord3 = smoothstep(0., fwidth(c)*3., c - .1) - smoothstep(0., fwidth(c)*2., c - .08);
			    col *= 1. + bord3*1.5;

			    // Another darker patch overlay to give a shadowy reflected look. Also made up.
			    float sh = max(c4 - c, 0.);
				col *= (1. - smoothstep(0.015, .05, sh)*.4);

			    // For some reason, I wanted a bit more shadow down here... I'm sure I had my reasons. :)
			    col -= (1.-bord2)*.1;

			    // Smoothstepping the original function value, then multiplying for oldschool, fake occlusion.
			    col *= smoothstep(0., .15, c)*.85 + .15;

			    // Postprocessing. Mixing in bit of ramped up color value to bring the color out more.
			    col = lerp(col, pow(max(col, 0.), float3(4,4,4)), .333);


			    // Rought gamma correction and screen presentation.
				return fixed4(sqrt(col), 1);
			}
			ENDCG
		}
	}
}
