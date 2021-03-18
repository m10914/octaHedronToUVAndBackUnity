using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class PlaneGenerator : MonoBehaviour
{
    public int segX;
    public int segY;

    public float size = 1.0f;

    private int storedX = -1;
    private int storedY = -1;
    private float storedSize = -1;
    private bool storedHemisphere = false;

    public Material mat;

    private MeshRenderer myMeshRend;
    private Material matInstance;
    private MeshFilter myMeshFilter;
    private Mesh myMesh;

    public bool Hemisphere = false; // determine if it's a hemisphere or a full octahedron

    void Start()
    {
        myMeshRend = gameObject.AddComponent<MeshRenderer>();

        if (!mat)
            myMeshRend.sharedMaterial = new Material(Shader.Find("Standard"));
        else myMeshRend.material = Instantiate(mat);

        matInstance = mat ? myMeshRend.material : myMeshRend.sharedMaterial;

        myMeshFilter = gameObject.AddComponent<MeshFilter>();
        myMesh = new Mesh();
    }


    void Update()
    {
        int calcX = (segX - 1) + segX;
        int calcY = (segY - 1) + segY;
        if(calcX != storedX || calcY != storedY || size != storedSize || storedHemisphere != Hemisphere)
        {
            storedX = calcX;
            storedY = calcY;
            storedSize = size;
            storedHemisphere = Hemisphere;

            if ((storedX % 2 == 0) || (storedY % 2 == 0))
            {
                Debug.Log("Stored dims should be odd! Now " + segX + ", " + segY + ", result is : " + storedX + ", " + storedY);
                Debug.Break();
            }

            GenerateGeometry();
        }

        matInstance.SetVector("_Params", new Vector4(Hemisphere ? 1 : -1, 0, 0, 0));
    }

    private void GenerateGeometry()
    {
        List<int> indices = new List<int>();
        List<Vector3> verts = new List<Vector3>();
        List<Vector2> uvs = new List<Vector2>();
        for(int j = 0; j < storedY; ++j)
        {
            for(int i = 0; i < storedX; ++i)
            {
                float dx = i / (storedX - 1.0f);
                float dy = j / (storedY - 1.0f);
                verts.Add(new Vector3(dx * size, 0, dy * size));
                uvs.Add(new Vector2(dx, dy));
            }
        }

        // generate indices - two ways
        int numQuadsX = storedX - 1;
        int numQuadsY = storedY - 1;

        //centric
        for(int i = 0; i < numQuadsX; ++i)
        {
            for(int j = 0; j < numQuadsY; ++j)
            {
                int A = i + j * storedX;
                int B = i + 1 + j * storedX;
                int C = i + 1 + (j + 1) * storedX;
                int D = i + (j + 1) * storedX;

                // now we determine quadrant
                if(
                    (i < numQuadsX*0.5f && j < numQuadsY*0.5f) ||
                    (i >= numQuadsX*0.5f && j >= numQuadsY*0.5f)
                )
                {
                    if (Hemisphere)
                    {
                        indices.Add(A); indices.Add(C); indices.Add(B);
                        indices.Add(A); indices.Add(D); indices.Add(C);
                    }
                    else
                    {
                        indices.Add(A); indices.Add(D); indices.Add(B);
                        indices.Add(B); indices.Add(D); indices.Add(C);
                    }
                }
                else
                {
                    if (Hemisphere)
                    {
                        indices.Add(A); indices.Add(D); indices.Add(B);
                        indices.Add(B); indices.Add(D); indices.Add(C);
                    }
                    else
                    {
                        indices.Add(A); indices.Add(C); indices.Add(B);
                        indices.Add(A); indices.Add(D); indices.Add(C);
                    }
                }
            }
        }
        

        myMesh.vertices = verts.ToArray();
        myMesh.triangles = indices.ToArray();
        myMesh.uv = uvs.ToArray();

        myMeshFilter.mesh = myMesh;
    }
}
