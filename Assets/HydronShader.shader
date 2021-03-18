Shader "Unlit/HydronShader"
{
    Properties
    {
        _LineColor("LineColor", Color) = (1,1,1,1)
        _FillColor("FillColor", Color) = (0,0,0,0)
        _WireThickness("Wire Thickness", RANGE(0, 800)) = 100
        [MaterialToggle] UseDiscard("Discard Fill", Float) = 1
        _Params("Params", Vector) = (0,0,0,0)
    }

    SubShader
    {
        Tags { "RenderType" = "Opaque" }


        Pass
        {
        // Wireframe shader based on the the following
        // http://developer.download.nvidia.com/SDK/10/direct3d/Source/SolidWireframe/Doc/SolidWireframe.pdf

        CGPROGRAM
        #pragma vertex vert
        #pragma geometry geom
        #pragma fragment frag
        #pragma multi_compile _ USEDISCARD_ON
        #include "UnityCG.cginc"

        float _WireThickness;
        float4 _Params;

        struct appdata
        {
            float4 vertex : POSITION;
            float2 uv : TEXCOORD0;
        };

        struct v2g
        {
            float4 projectionSpaceVertex : SV_POSITION;
            float4 worldSpacePosition : TEXCOORD1;
        };

        struct g2f
        {
            float4 projectionSpaceVertex : SV_POSITION;
            float4 worldSpacePosition : TEXCOORD0;
            float4 dist : TEXCOORD1;
        };


        float2 UVToOctahedron_Full(float3 dir)
        {
            float3 oct = sign(dir);

            float sum = dot(dir, oct);
            float3 octahedron = dir / sum;

            if (octahedron.y < 0.0f)
            {
                float3 absOct = abs(octahedron);
                octahedron.xz = oct.xz * float2(1.0f - absOct.z, 1.0f - absOct.x);
            }
            return octahedron.xz;
        }

        float2 UVToOctahedron_Semi(float3 dir)
        {
            float3 oct = sign(dir);

            float sum = dot(dir, oct);
            float3 octahedron = dir / sum;

            return float2(
                octahedron.x + octahedron.z,
                octahedron.z - octahedron.x);
        }

        float3 OctahedronToUV_Full(float2 uv)
        {
            uv = (uv - 0.5f) * 2.0f;
            float3 pos = float3(uv.x, 0.0f, uv.y);
            float2 absolute = abs(pos.xz);
            pos.y = 1.0f - absolute.x - absolute.y;

            if (pos.y < 0.0f)
            {
                pos.xz = sign(pos.xz) * float2(1.0f - absolute.y, 1.0f - absolute.x);
            }

            return pos;
        }

        float3 OctahedronToUV_Hemi(float2 uv)
        {
            float3 pos = float3(uv.x - uv.y, 0.0f, -1.0f + uv.x + uv.y);
            float2 absolute = abs(pos.xz);
            pos.y = 1.0f - absolute.x - absolute.y;

            return pos;
        }


        v2g vert(appdata v)
        {
            v2g o;

            float3 ov = v.vertex;

            float lerpo = saturate((sin(_Time.y / 2.0f) + 0.5f) * 2.0f);

            // project uv to hydron
            float3 np;
            if(_Params.x > 0)
                np = normalize(OctahedronToUV_Hemi(v.uv)) / 2.0f + 0.5f;
            else
                np = normalize(OctahedronToUV_Full(v.uv)) / 2.0f + 0.5f;
            v.vertex.xyz = lerp(ov, np, lerpo);

            o.projectionSpaceVertex = UnityObjectToClipPos(v.vertex);
            o.worldSpacePosition = mul(unity_ObjectToWorld, v.vertex);
            return o;
        }

        [maxvertexcount(3)]
        void geom(triangle v2g i[3], inout TriangleStream<g2f> triangleStream)
        {
            float2 p0 = i[0].projectionSpaceVertex.xy / i[0].projectionSpaceVertex.w;
            float2 p1 = i[1].projectionSpaceVertex.xy / i[1].projectionSpaceVertex.w;
            float2 p2 = i[2].projectionSpaceVertex.xy / i[2].projectionSpaceVertex.w;

            float2 edge0 = p2 - p1;
            float2 edge1 = p2 - p0;
            float2 edge2 = p1 - p0;

            float area = abs(edge1.x * edge2.y - edge1.y * edge2.x);
            float wireThickness = 800 - _WireThickness;

            g2f o;
            o.worldSpacePosition = i[0].worldSpacePosition;
            o.projectionSpaceVertex = i[0].projectionSpaceVertex;
            o.dist.xyz = float3((area / length(edge0)), 0.0, 0.0) * o.projectionSpaceVertex.w * wireThickness;
            o.dist.w = 1.0 / o.projectionSpaceVertex.w;
            triangleStream.Append(o);

            o.worldSpacePosition = i[1].worldSpacePosition;
            o.projectionSpaceVertex = i[1].projectionSpaceVertex;
            o.dist.xyz = float3(0.0, (area / length(edge1)), 0.0) * o.projectionSpaceVertex.w * wireThickness;
            o.dist.w = 1.0 / o.projectionSpaceVertex.w;
            triangleStream.Append(o);

            o.worldSpacePosition = i[2].worldSpacePosition;
            o.projectionSpaceVertex = i[2].projectionSpaceVertex;
            o.dist.xyz = float3(0.0, 0.0, (area / length(edge2))) * o.projectionSpaceVertex.w * wireThickness;
            o.dist.w = 1.0 / o.projectionSpaceVertex.w;
            triangleStream.Append(o);
        }

        uniform fixed4 _LineColor;
        uniform fixed4 _FillColor;

        fixed4 frag(g2f i) : SV_Target
        {
            float minDistanceToEdge = min(i.dist[0], min(i.dist[1], i.dist[2])) * i.dist[3];

        // Early out if we know we are not on a line segment.
        if (minDistanceToEdge > 0.9)
        {
            #ifdef USEDISCARD_ON
            discard;
            #else
            return _FillColor;
            #endif
        }

        return _LineColor;
    }
    ENDCG
}
    }
}