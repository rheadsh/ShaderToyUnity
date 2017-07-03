using UnityEngine;

public class SendMousePos : MonoBehaviour
{

    Material mat;

    // Use this for initialization
    void Start()
    {
        mat = GetComponent<ShaderCam>().material;
    }

    // Update is called once per frame
    void Update()
    {
		if (Input.GetMouseButton(0))
			mat.SetVector("_Mouse", Input.mousePosition);
            
    }
}
