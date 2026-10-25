// MC Braziers (mcbraziers): braziers glow only on their flame and embers.
// They use Solas's soul, copper torch and nether portal light colours (blocklightColor.glsl), but those blocks' glow
// rules also light pale or blue-green metal (iron, prismarine, oxidized copper), so braziers get their own ids and
// these stricter colour tests. A diamond brazier with soul fire still glows: its texture is the soul flame's colour.
else if (material == 98) { // soul fire: blue, and colourful or near-white
    float brightest = max(albedo.r, max(albedo.g, albedo.b));
    float chroma = brightest - min(albedo.r, min(albedo.g, albedo.b));
    emission = int(albedo.b > 0.5 && (chroma > 0.35 || brightest >= 0.95));
}
else if (material == 99) { // copper fire: clearly green
    emission = int(albedo.g > 0.5 && albedo.g - max(albedo.r, albedo.b) > 0.2);
}
else if (material == 100) { // amethyst fire: purple, or near-white with a purple cast
    float brightest = max(albedo.r, max(albedo.g, albedo.b));
    emission = int((albedo.b - albedo.g > 0.25 && albedo.r - albedo.g > 0.1) || (brightest >= 0.95 && albedo.r > albedo.g));
}
