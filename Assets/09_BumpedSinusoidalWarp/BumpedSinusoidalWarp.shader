Shader "Hidden/RoundVoronoiBorders"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_Tex ("UV Texture", 2D) = "white" {}
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
			#include "BumpedSinusoidalWarpBase.cginc"

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
			sampler2D _Tex;

			fixed4 frag (v2f i) : SV_Target
			{
				// Screen coordinates.
				float2 uv = (i.vertex.xy - _ScreenParams.xy*.5)/_ScreenParams.y;


			    // PLANE ROTATION
			    //
			    // Rotating the canvas back and forth. I don't feel it adds value, in this case,
			    // but feel free to uncomment it.
			    //float th = sin(_Time.y*0.1)*sin(_Time.y*0.12)*2.;
			    //float cs = cos(th), si = sin(th);
			    //uv *= mat2(cs, -si, si, cs);


			    // VECTOR SETUP - surface postion, ray origin, unit direction vector, and light postion.
			    //
			    // Setup: I find 2D bump mapping more intuitive to pretend I'm raytracing, then lighting a bump mapped plane
			    // situated at the origin. Others may disagree. :)
			    float3 sp = float3(uv, 0); // Surface posion. Hit point, if you prefer. Essentially, a screen at the origin.
			    float3 rd = normalize(float3(uv, 1.)); // Unit direction vector. From the origin to the screen plane.
			    float3 lp = float3(cos(_Time.y)*0.5, sin(_Time.y)*0.2, -1.); // Light position - Back from the screen.
				float3 sn = float3(0., 0., -1); // Plane normal. Z pointing toward the viewer.


			/*
				// I deliberately left this block in to show that the above is a simplified version
				// of a raytraced plane. The "rayPlane" equation is commented out above.
				float3 rd = normalize(float3(uv, 1.));
				float3 ro = float3(0., 0., -1);

				// Plane normal.
				float3 sn = normalize(float3(cos(_Time.y)*0.25, sin(_Time.y)*0.25, -1));
			    //float3 sn = normalize(float3(0., 0., -1));

				float3 sp = rayPlane(float3(0., 0., 0.), ro, sn, rd);
			    float3 lp = float3(cos(_Time.y)*0.5, sin(_Time.y)*0.25, -1.);
			*/


			    // BUMP MAPPING - PERTURBING THE NORMAL
			    //
			    // Setting up the bump mapping variables. Normally, you'd amalgamate a lot of the following,
			    // and roll it into a single function, but I wanted to show the workings.
			    //
			    // f - Function value
			    // fx - Change in "f" in in the X-direction.
			    // fy - Change in "f" in in the Y-direction.
			    float2 eps = float2(4./_ScreenParams.y, 0.);

			    float f = bumpFunc(sp.xy); // Sample value multiplied by the amplitude.
			    float fx = bumpFunc(sp.xy-eps.xy); // Same for the nearby sample in the X-direction.
			    float fy = bumpFunc(sp.xy-eps.yx); // Same for the nearby sample in the Y-direction.

			 	// Controls how much the bump is accentuated.
				const float bumpFactor = 0.05;

			    // Using the above to determine the dx and dy function gradients.
			    fx = (fx-f)/eps.x; // Change in X
			    fy = (fy-f)/eps.x; // Change in Y.
			    // Using the gradient vector, "float3(fx, fy, 0)," to perturb the XY plane normal ",float3(0, 0, -1)."
			    // By the way, there's a redundant step I'm skipping in this particular case, on account of the
			    // normal only having a Z-component. Normally, though, you'd need the commented stuff below.
			    //float3 grad = float3(fx, fy, 0);
			    //grad -= sn*dot(sn, grad);
			    //sn = normalize( sn + grad*bumpFactor );
			    sn = normalize( sn + float3(fx, fy, 0)*bumpFactor );


			    // LIGHTING
			    //
				// Determine the light direction vector, calculate its distance, then normalize it.
				float3 ld = lp - sp;
				float lDist = max(length(ld), 0.001);
				ld /= lDist;

			    // Light attenuation.
			    float atten = 1./(1.0 + lDist*lDist*0.15);
				//float atten = min(1./(lDist*lDist*1.), 1.);

			    // Using the bump function, "f," to darken the crevices. Completely optional, but I
			    // find it gives extra depth.
			    atten *= f*.9 + .1; // Or... f*f*.7 + .3; //  pow(f, .75); // etc.



				// Diffuse value.
				float diff = max(dot(sn, ld), 0.);
			    // Enhancing the diffuse value a bit. Made up.
			    diff = pow(diff, 4.)*0.66 + pow(diff, 8.)*0.34;
			    // Specular highlighting.
			    float spec = pow(max(dot( reflect(-ld, sn), -rd), 0.), 12.);


			    // TEXTURE COLOR
			    //
				// Combining the surface postion with a fraction of the warped surface position to index
			    // into the texture. The result is a slightly warped texture, as a opposed to a completely
			    // warped one. By the way, the warp function is called above in the "bumpFunc" function,
			    // so it's kind of wasteful doing it again here, but the function is kind of cheap, and
			    // it's more readable this way.
			    float3 texCol = tex2D(_Tex, sp.xy + W(sp.xy)/8.).xyz;
			    // Rough sRGB to linear conversion with processaing... That's a whole other conversation. :)
			    texCol = smoothstep(0.05, .75, pow(texCol*texCol, float3(.75, .8, .85)));

			    // Textureless. Simple and elegant... so it clearly didn't come from me. Thanks Fabrice. :)
			    //float3 texCol = smoothFract( W(sp.xy).xyy )*.1 + .2;



			    // FINAL COLOR
			    // Using the values above to produce the final color.
			    float3 col = (texCol * (diff*float3(1, .97, .92)*2. + 0.5) + float3(1., .6, .2)*spec*2.)*atten;


			    // Perform some statistically unlikely (but close enough) 2.0 gamma correction. :)
				return fixed4(sqrt(clamp(col, 0., 1.)), 1.);
			}
			ENDCG
		}
	}
}
