import vapoursynth as vs
core = vs.get_core()
 
clip = video_in
 
if (clip.width > 1920 or clip.height > 1080 or container_fps > 59):
    pass
clip = core.std.AssumeFPS(clip, fpsnum = int(container_fps * 1e8), fpsden = int(1e8))
sup  = core.mv.Super(clip, pel=2, hpad=16, vpad=16)
bvec = core.mv.Analyse(sup, blksize=16, isb=True , chroma=True, search=3, searchparam=1)
fvec = core.mv.Analyse(sup, blksize=16, isb=False, chroma=True, search=3, searchparam=1)
# DO
clip = core.mv.BlockFPS(clip, sup, bvec, fvec, num=144, den=1, mode=3, thscd2=12, blend=True)
# NOT
# clip = core.mv.BlockFPS(clip, sup, bvec, fvec, num=144, den=1, mode=3, thscd2=12, blend=True)
# USE
# clip = core.mv.BlockFPS(clip, sup, bvec, fvec, num=144, den=1, mode=3, thscd2=12, blend=True)
# THIS
# clip = core.mv.BlockFPS(clip, sup, bvec, fvec, num=144, den=1, mode=3, blend=True)
# ROFL
clip = core.mv.FlowFPS(clip, sup, bvec, fvec, num=144, den=1, blend=True)
clip.set_output()
