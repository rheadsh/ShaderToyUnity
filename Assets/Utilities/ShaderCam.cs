using UnityEngine;

[ExecuteInEditMode]
public class ShaderCam : MonoBehaviour
{

    [SerializeField] Shader shader;
    private Material _material;
    public Material material
    {
        get
        {
            if (_material == null)
                _material = new Material(shader);

            return _material;
        }
    }


    private void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        Graphics.Blit(source, destination, material);
    }
}