// p144 �⺻ ���ǽ� ���̴�
Shader "Custom/SurfaceShaderNormalMap"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        _SecondAlbedo ("Second Albedo (RGB)", 2D) = "white" {}
        _AlbedoLerp ("Albedo Lerp", Range(0, 1)) = 0.5
        _Glossiness ("Smoothness", Range(0,1)) = 0.5
        _Metallic ("Metallic", Range(0,1)) = 0.0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 200

        CGPROGRAM
        // ���� ��� ǥ�� ������ �� ���, ��� ���� Ÿ�Կ� �׸��� Ȱ��ȭ
        #pragma surface surf Standard fullforwardshadows

        // ������ ȿ���� �� ���� ���̵��� ���̴� �� 3.0 Ÿ�� ���
        #pragma target 3.0

        sampler2D _MainTex;
        sampler2D _SecondAlbedo;
        half _AlbedoLerp;

        struct Input
        {
            float2 uv_MainTex;
        };

        half _Glossiness;
        half _Metallic;
        fixed4 _Color;

        // �ش� ���̴��� �ν��Ͻ� ����Ʈ�� �߰��Ѵ�. �� ���̴��� Ȱ���ϴ� ������ '�ν��Ͻ� Ȱ��ȭ'�� üũ�ؾ� �Ѵ�.
        // �ν��Ͻ̿� ���� �ڼ��� ������ https://docs.unityed.com/Manual/GPUInstancing.html�� ����Ʈ�� �����Ѵ�.
        // #pragma instancing_options assumeuniformscaling
        UNITY_INSTANCING_BUFFER_START(Props)
            // �� �ν��Ͻ��� ������Ƽ�� ���⿡ �ִ´�.
        UNITY_INSTANCING_BUFFER_END(Props)

        void surf (Input IN, inout SurfaceOutputStandard o)
        {
            // Albedo comes from a texture tinted by color
            // ������ ����� �ؽ�ó���� �˺������� �����´�.
            fixed4 c = tex2D (_MainTex, IN.uv_MainTex);
            fixed4 secondAlbedo = tex2D(_SecondAlbedo, IN.uv_MainTex);
            o.Albedo = lerp(c, secondAlbedo, _AlbedoLerp) * _Color;
            // �ݼӼ�(metallic)�� �ε巯��(smoothness)������ �����̴� �������� �����´�.
            o.Metallic = _Metallic;
            o.Smoothness = _Glossiness;
            o.Alpha = c.a;
        }
        ENDCG
    }
    FallBack "Diffuse"
}
