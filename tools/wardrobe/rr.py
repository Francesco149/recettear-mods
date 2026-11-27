"""ctypes binding of the loader's region-recolour kernel (recettear-mod-loader core/recolor.c + imgfile.c,
built by `make -C ../recettear-mod-loader/tools/librecolor`): the authoring tool runs the exact code the
loader runs at texture load."""
import ctypes as C, os

LIB = os.environ.get('RR_LIB') or os.path.join(os.path.dirname(__file__), '../../../recettear-mod-loader/build/librecolor.so')
_l = C.CDLL(os.path.abspath(LIB))
_l.rr_parse.restype = C.c_void_p; _l.rr_parse.argtypes = [C.c_char_p, C.c_char_p, C.c_int]
_l.rr_free.argtypes = [C.c_void_p]
for f in ('rr_regions', 'rr_images'):
    getattr(_l, f).argtypes = [C.c_void_p]
for f in ('rr_region_id', 'rr_region_name', 'rr_image_glob'):
    getattr(_l, f).argtypes = [C.c_void_p, C.c_int]; getattr(_l, f).restype = C.c_char_p
_l.rr_region_hidden.argtypes = [C.c_void_p, C.c_int]
_l.rr_match.argtypes = [C.c_void_p, C.c_char_p]
_l.rr_segment.argtypes = [C.c_void_p, C.c_int, C.c_char_p, C.c_int, C.c_int, C.c_void_p, C.c_void_p]


class Target(C.Structure):
    _fields_ = [('on', C.c_int), ('L', C.c_float), ('a', C.c_float), ('b', C.c_float)]


_l.rr_apply.argtypes = [C.c_void_p, C.c_void_p, C.c_void_p, C.c_void_p, C.c_int, C.c_int, C.POINTER(Target)]
_l.rr_rgb_to_lab.argtypes = [C.c_int] * 3 + [C.POINTER(C.c_float)] * 3
_l.rr_img_decode = getattr(_l, 'img_decode')
_l.img_decode.restype = C.c_void_p
_l.img_decode.argtypes = [C.c_char_p, C.c_size_t, C.POINTER(C.c_int), C.POINTER(C.c_int), C.POINTER(C.c_int)]


def lab(r, g, b):
    L, A, B = C.c_float(), C.c_float(), C.c_float()
    _l.rr_rgb_to_lab(r, g, b, C.byref(L), C.byref(A), C.byref(B))
    return L.value, A.value, B.value


def hex_lab(h):
    h = h.lstrip('#')
    return lab(int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16))


def decode(data: bytes):
    """file bytes -> (rgba bytes top-down, w, h, kind) via the loader's imgfile.c"""
    w, h, k = C.c_int(), C.c_int(), C.c_int()
    p = _l.img_decode(data, len(data), C.byref(w), C.byref(h), C.byref(k))
    if not p:
        return None
    out = C.string_at(p, w.value * h.value * 4)
    C.CDLL(None).free(C.c_void_p(p))
    return out, w.value, h.value, k.value


class Rules:
    def __init__(self, text: str):
        err = C.create_string_buffer(256)
        self.p = _l.rr_parse(text.encode(), err, 256)
        if not self.p:
            raise ValueError(err.value.decode())
        self.regions = [(_l.rr_region_id(self.p, i).decode(), _l.rr_region_name(self.p, i).decode(),
                         bool(_l.rr_region_hidden(self.p, i))) for i in range(_l.rr_regions(self.p))]
        self.images = [_l.rr_image_glob(self.p, i).decode() for i in range(_l.rr_images(self.p))]

    def __del__(self):
        if getattr(self, 'p', None):
            _l.rr_free(self.p)

    def match(self, path):
        return _l.rr_match(self.p, path.lower().replace('\\', '/').encode())

    def segment(self, image, rgba, w, h):
        seg = C.create_string_buffer(w * h); wt = C.create_string_buffer(w * h)
        n = _l.rr_segment(self.p, image, rgba, w, h, seg, wt)
        return seg.raw, wt.raw, n

    def apply(self, seg, wt, rgba, w, h, targets: dict):
        """targets: region id -> '#rrggbb'; returns (new rgba, changed)"""
        T = (Target * len(self.regions))()
        for i, (rid, _, _) in enumerate(self.regions):
            if targets.get(rid):
                T[i].on = 1; T[i].L, T[i].a, T[i].b = hex_lab(targets[rid])
        buf = C.create_string_buffer(bytes(rgba), len(rgba))
        n = _l.rr_apply(self.p, seg, wt, buf, w, h, T)
        return buf.raw[:len(rgba)], n
