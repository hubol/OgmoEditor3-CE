precision mediump float;
uniform vec3 tint;
uniform float alpha;
uniform sampler2D texture;
varying vec2 v_textcoord;

void main(void)
{
	gl_FragColor = texture2D(texture, v_textcoord) * vec4(tint, alpha);
}