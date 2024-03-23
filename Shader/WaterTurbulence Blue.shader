Shader "Custom/WaterTurbulence"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Speed ("Speed", Float) = 0.5
        _Intensity ("Intensity", Float) = 0.005
    }
    SubShader
    {
        Tags { "Queue"="Transparent" "RenderType"="Transparent" }
        Blend SrcAlpha OneMinusSrcAlpha
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"
            
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
            
            sampler2D _MainTex;
            float _Speed;
            float _Intensity;

            v2f vert(appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }
            
            fixed4 frag(v2f i) : SV_Target
            {
                float2 uv = i.uv;
                
                float time = _Time.y * 0.5 + 23.0;
                float TAU = 6.28318530718;
                int MAX_ITER = 5;
                
                #ifdef SHOW_TILING
                float2 p = fmod(uv * TAU * 2.0, TAU) - 250.0;
                #else
                float2 p = fmod(uv * TAU, TAU) - 250.0;
                #endif

                float2 j = p;
                float c = 1.0;
                
                for (int n = 0; n < MAX_ITER; n++)
                {
                    float t = time * (1.0 - (3.5 / float(n + 1)));
                    j = p + float2(cos(t - j.x) + sin(t + j.y), sin(t - j.y) + cos(t + j.x));
                    c += 1.0 / length(float2(p.x / (sin(j.x + t) / _Intensity), p.y / (cos(j.y + t) / _Intensity)));
                }
                c /= float(MAX_ITER);
                c = 1.17 - pow(c, 1.4);
                float3 colour = pow(abs(c), 8.0);
                colour = clamp(colour + float3(0.0, 0.35, 0.5), 0.0, 1.0);
                
                #ifdef SHOW_TILING
                // Flash tile borders...
                float2 pixel = 2.0 / _ScreenParams.xy;
                uv *= 2.0;
                float f = floor(mod(_Time.y * 0.5, 2.0));    // Flash value.
                float2 first = step(pixel, uv) * f;            // Rule out first screen pixels and flash.
                uv = step(frac(uv), pixel);                    // Add one line of pixels per tile.
                colour = lerp(colour, float3(1.0, 1.0, 0.0), (uv.x + uv.y) * first.x * first.y); // Yellow line
                #endif

                return fixed4(colour, 1.0);
            }
            ENDCG
        }
    }
}