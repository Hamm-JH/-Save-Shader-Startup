// p121 스펙큘러 추가
Shader "Custom/SpecularShader"
{
    Properties
    {
        _Color ("Color", Color) = (1, 0, 0, 1)
        _DiffuseTex ("Texture", 2D) = "white" {}
        _Ambient ("Ambient", Range(0, 1)) = 0.25
        // 두 개의 신규 속성 추가
        // 스펙큘러 색상
        _SpecColor("Specular material Color", Color) = (1, 1, 1, 1)
        // 스펙큘러 강도
        _Shininess("Shininess", Float) = 10
    }
    SubShader
    {
        Tags { "LightMode" = "ForwardBase"}
        LOD 100
        
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            #include "UnityLightingCommon.cginc"
            
            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float2 uv : TEXCOORD0;  
            };

            // [출력 구조체 v2f] v2f : vertex to fragment
            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertexClip : SV_POSITION;
                // 월드 공간 정점 위치 계산용
                // 정점 셰이더에서 계산해서 프래그먼트에 전달용
                // vertexWorld 추가 이유 :
                // - 프레그먼트 셰이더 -> 광원 방향 벡터 계산때문
                // - 광원방향 벡터계산을 정점셰이더에서 수행가능 / 이를 버텍스릿(vertex-lit)이라고 부름
                // -- 이를 프레그먼트 셰이더에서 수행해도 좋음
                float4 vertexWorld : TEXCOORD2;
                float3 worldNormal : TEXCOORD1;
            };

            sampler2D _DiffuseTex;
            float4 _DiffuseTex_ST;
            float4 _Color;
            float _Ambient; // 내적값을 보간하는 변수 추가
            float _Shininess;

            // 정점셰이더
            v2f vert (appdata v)
            {
                v2f o;
                o.vertexClip = UnityObjectToClipPos(v.vertex);
                // 정점위치 계산
                // - unity_ObjectToWorld : 정점위치 -> 월드 공간 위치 변환에 필요한 행렬
                o.vertexWorld = mul(unity_ObjectToWorld, v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _DiffuseTex);    
                float3 worldNormal = UnityObjectToWorldNormal(v.normal);
                o.worldNormal = worldNormal;
                return o;
            }

            // 프레그먼트
            fixed4 frag (v2f i) : SV_Target
            {
                // 스펙큘러 계산에 필요한값 정규화 (노멀, 정규화된 뷰 방향, 정규화된 광원 방향 벡터)
                // - 좋은 출력 도출용으로 변환마친 벡터 정규화 필요. (상황따라 안할수 있지만 안해서 망할수있음)
                // - 여기 값은 동일한 월드공간 기준(i.vertexWorld)
                float3 normalDirection = normalize(i.worldNormal);
                float3 viewDirection = normalize(UnityWorldSpaceViewDir(i.vertexWorld));
                float3 lightDirection = normalize(UnityWorldSpaceLightDir(i.vertexWorld));

                // 텍스처 샘플링
                float4 tex = tex2D(_DiffuseTex, i.uv);

                // 디퓨저(람버트) 구현
                float nl = max(_Ambient, dot(normalDirection, _WorldSpaceLightPos0.xyz));
                float4 diffuseTerm = nl * _Color * tex * _LightColor0;

                // 스펙큘러(퐁) 구현
                // reflect 계산
                // - lightDirecton에 음수기호 넣음 : 방향을 객체 -> 광원으로 향하게 함
                float3 reflectionDirection = reflect(-lightDirection, normalDirection);
                // 내적 계산 (해당 표면 디퓨즈에서 빛 반사량 계산)
                /*
                * - 디퓨즈 효과 : 광원 방향벡터 - 노멀 벡터 사이에서 일어남.
                * -- 여기선 거울 반사 방향 벡터 - 뷰 방향 벡터 사이
                * - 스펙큘러 항은 시야에 의존적
                * -- ★ 내적 값은 음수될수 없음 (빛은 음수일수 없음)
                */
                float3 specularDot = max(0.0, dot(viewDirection, reflectionDirection));
                float3 specular = pow(specularDot, _Shininess);
                
                // 최종 출력에 스펙큘러값 더함
                /*
                * 디퓨저 계산시 값에 표면색상값 곱한것처럼
                * 스펙큘러에서도 스펙큘러 생성 값을 곱함.
                */
                float4 specularTerm = float4(specular, 1) * _SpecColor * _LightColor0;

                float4 finalColor = diffuseTerm + specularTerm;
                return finalColor;
            }
            ENDCG
        } 
    }
}
