#include <boost/python.hpp>

__int128_t mul(__int128_t x) { return x * x; }

BOOST_PYTHON_MODULE(libextension) {}
