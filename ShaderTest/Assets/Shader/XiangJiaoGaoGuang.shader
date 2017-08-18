Shader "MyShader/XiangJiaoGaoGuang" {
	Properties {
		_MainColor ("Color" , Color) = (1,1,1,1)
		_HighlightColor("HighlightColor" ,Color) = (0,0,1,1)
		_EdgePow("Threshold" , Range(0 , 5)) = 0.5
		_RimNum("Rim" , Range(0 , 5)) = 1
		_MainTex("Main Tex" , 2D) = "white"{}
		_MaskTex("Mask Tex" ,  2D) = "white" {}
		_speed("Speed" ,Range(0 , 2)) = 1.0
	}

	SubShader {

	Tags {"Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent" "DisableBatching"="True"}
	
	Pass{
		Tags { "LightMode"="ForwardBase" }	
		
		Blend One One
		ZWrite Off
		Cull Off
		
		CGPROGRAM

		#include "UnityCG.cginc"

		#pragma vertex vert
		#pragma fragment frag

		#define UNITY_PASS_FORWARDBASE
        #pragma multi_compile_fwdbase

		float4 _MainColor;
		float4 _HighlightColor;
		sampler2D _CameraDepthTexture;
		float _EdgePow;
		sampler2D _MainTex;
		float4 _MainTex_ST;
		sampler2D _MaskTex;
		float _speed;
		float _RimNum;

		struct a2v{
			float4 vertex:POSITION;
			float3 normal:NORMAL;
			float2 tex:TEXCOORD0;
		};

		struct v2f{
			float4 pos:POSITION;
			float4 scrPos:TEXCOORD0;
			half3 worldNormal:TEXCOORD1;
			half3 worldViewDir:TEXCOORD2;
			float2 uv:TEXCOORD3;
		};

		v2f vert (a2v v )
		{
			v2f o;

			o.pos = UnityObjectToClipPos ( v.vertex );

			o.scrPos = ComputeScreenPos ( o.pos );

			float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz; 
		
			o.worldViewDir = normalize(UnityWorldSpaceViewDir(worldPos));
			o.worldNormal = UnityObjectToWorldNormal(v.normal); 

			o.uv = TRANSFORM_TEX(v.tex , _MainTex);

			COMPUTE_EYEDEPTH(o.scrPos.z);
			return o;
		}
	
		fixed4 frag ( v2f i ) : SV_TARGET
		{
			//纹理动画和Mask部分，主要作用是实现扫描效果还有六边形图案
			fixed mainTex = 1 - tex2D(_MainTex , i.uv).a;
			fixed mask = tex2D(_MaskTex , i.uv + float2(0 , (_Time.y)*_speed)).r;
			fixed4 finalColor = lerp(_MainColor , _HighlightColor , mainTex);
			finalColor=lerp(fixed4(0,0,0,1),finalColor,mask);
		
			//获取深度图和clip space的深度值
			float sceneZ = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE_PROJ(_CameraDepthTexture, UNITY_PROJ_COORD(i.scrPos)));
			float partZ = i.scrPos.z;

			//diff为比较两个深度值，rim为Phong：在边缘位置加上一层_HighlightColor的颜色
 			float diff = 1-saturate((sceneZ-i.scrPos.z)*4 - _EdgePow);
			half rim = pow(1 - abs(dot(normalize(i.worldNormal),normalize(i.worldViewDir))) , _RimNum);

			//最后通过插值混合颜色
			finalColor = lerp(finalColor, _HighlightColor, diff);
			finalColor = lerp(finalColor, _HighlightColor, rim);
			return finalColor;
		}

		ENDCG
		}
	}
}
