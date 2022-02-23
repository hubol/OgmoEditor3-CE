package rendering;

import util.Vector;
import js.node.Path;
import js.node.Fs;
import js.html.webgl.RenderingContext;
import js.html.webgl.Program;
import js.html.webgl.UniformLocation;

class Shader
{
	public var gl: RenderingContext;
	public var program: Program;
	public var vertexPositionAttribute: Int;
	public var vertexColorAttribute: Int;
	public var vertexUVAttribute: Int;
	public var uniforms: Map<String, UniformLocation> = new Map();

	public function new(gl: RenderingContext, shader:String)
	{
		this.gl = gl;

		// Create the Shaders
		var vertexShader = getShader(shader + ".vs");
		var fragmentShader = getShader(shader + ".fs");

		// Create the shader program
		program = gl.createProgram();
		gl.attachShader(program, vertexShader);
		gl.attachShader(program, fragmentShader);
		gl.linkProgram(program);

		// Delete the shaders (no longer used now that the Program is created)
		gl.deleteShader(vertexShader);
		gl.deleteShader(fragmentShader);

		// Make sure shader creation suceeded
		if (!gl.getProgramParameter(program, RenderingContext.LINK_STATUS)) throw "Unable to initialize the shader program.";

		// get attributes
		vertexPositionAttribute = gl.getAttribLocation(program, "a_position");
		vertexColorAttribute = gl.getAttribLocation(program, "a_color");
		vertexUVAttribute = gl.getAttribLocation(program, "a_textcoord");
	}
	
	public function dispose(): Void
	{
		gl.deleteProgram(program);
	}

	private function findUniformLocation(name: String) {
		if (uniforms[name] == null) uniforms[name] = gl.getUniformLocation(program, name);
		return uniforms[name];
	}

	public function setUniform1f(name: String, value: Float): Void
	{
		gl.uniform1f(findUniformLocation(name), value);
	}
	
	public function setUniform2f(name: String, vec:Vector): Void
	{
		gl.uniform2f(findUniformLocation(name), vec.x, vec.y);
	}

	public function setUniform3f(name: String, x: Float, y: Float, z: Float): Void
	{
		gl.uniform3f(findUniformLocation(name), x, y, z);
	}

	function getShader(path: String): js.html.webgl.Shader
	{
		var type = (Path.extname(path) == ".vs" ? RenderingContext.VERTEX_SHADER : RenderingContext.FRAGMENT_SHADER);
		var shader:js.html.webgl.Shader = gl.createShader(type);
		var source = Fs.readFileSync(Path.join(OGMO.root, "shaders/" + path), "utf8");

		// Compile the shader program
		gl.shaderSource(shader, source);
		gl.compileShader(shader);

		// See if it compiled successfully
		if (!gl.getShaderParameter(shader, RenderingContext.COMPILE_STATUS))
			throw "An error occurred compiling the shaders: " + gl.getShaderInfoLog(shader);

		return shader;
	}
}
