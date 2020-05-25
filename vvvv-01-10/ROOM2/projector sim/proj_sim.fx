//shading:         constant color
//lighting model:  none
//lighting type:   none

// --------------------------------------------------------------------------------------------------
// PARAMETERS:
// --------------------------------------------------------------------------------------------------

//transforms
float4x4 tW: WORLD;        //the models world matrix
float4x4 tV: VIEW;         //view matrix as set via Renderer (EX9)
float4x4 tP: PROJECTION;   //projection matrix as set via Renderer (EX9)
float4x4 tWVP: WORLDVIEWPROJECTION;
float4x4 tVP: VIEWPROJECTION;

float4x4 tProjectorV;
float4x4 tProjectorP;

//material properties
float4 cAmb : COLOR <String uiname="Color";>  = {1, 1, 1, 0.1};

//texture
texture Tex <string uiname="Texture";>;
sampler Samp = sampler_state    //sampler for doing the texture-lookup
{
    Texture   = (Tex);          //apply a texture to the sampler
    MipFilter = LINEAR;         //sampler states
    MinFilter = LINEAR;
    MagFilter = LINEAR;
};

float4x4 tTex: TEXTUREMATRIX <string uiname="Texture Transform";>;

//the data structure: "vertexshader to pixelshader"
//used as output data with the VS function
//and as input data with the PS function
struct vs2ps
{
    float4 Pos : POSITION;
    float4 TexCd : TEXCOORD0;
    float4 PosW : TEXCOORD1;
    float4 PosProjectorSpace : TEXCOORD2;
};

// --------------------------------------------------------------------------------------------------
// VERTEXSHADERS
// --------------------------------------------------------------------------------------------------

vs2ps VS(
    float4 Pos : POSITION,
    float4 TexCd : TEXCOORD0)
{
    //inititalize all fields of output struct with 0
    vs2ps Out = (vs2ps)0;

    //transform position
    Out.Pos = mul(Pos, tWVP);

    //transform texturecoordinates
    Out.TexCd = mul(TexCd, tTex);
    Out.PosW = mul(Pos,tW);

    return Out;
}

// --------------------------------------------------------------------------------------------------
// PIXELSHADERS:
// --------------------------------------------------------------------------------------------------

float4 PS(vs2ps In): COLOR
{
    float4 PosProjectorSpace = mul(mul(In.PosW,tProjectorV),tProjectorP);
    
    //In.TexCd = In.TexCd / In.TexCd.w; // for perpective texture projections (e.g. shadow maps) ps_2_0
    float2 texoords=(PosProjectorSpace.xy/2+float2(0.5,-0.5));
    float4 col = tex2D(Samp, texoords);
    float isInsideFrustum = 1;
    
    isInsideFrustum = (PosProjectorSpace.z>0) * (abs(PosProjectorSpace.x)<1) * (abs(PosProjectorSpace.y)<1);

    col= (isInsideFrustum*col) + (!isInsideFrustum*cAmb);
    // use this to get projector space co-ords instead
    // col=PosProjectorSpace;
    return col;
}

// --------------------------------------------------------------------------------------------------
// TECHNIQUES:
// --------------------------------------------------------------------------------------------------

technique TConstant
{
    pass P0
    {
        //Wrap0 = U;  // useful when mesh is round like a sphere
        VertexShader = compile vs_2_0 VS();
        PixelShader = compile ps_2_0 PS();
    }
}
