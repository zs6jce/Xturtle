package de.itemis.tooling.xturtle.resource

import org.eclipse.emf.common.util.URI
import org.junit.Assert
import org.junit.Test
import de.itemis.tooling.xturtle.resource.TurtleUriResolver$PrefixURI

//http://jsfiddle.net/ecmanaut/RHdnZ/ allows online URI resolution
class ResolveUriTest {

	var PrefixURI uri

//these examples taken from http://www.ietf.org/rfc/rfc3986.txt section 5.4
//examples commented out are not successfully resolved
//base uri is "http://a/b/c/d;p?q"
	val examples='''
«««5.4.1.  Normal Examples
      "g:h"           =  "g:h"
      "g"             =  "http://a/b/c/g"
      "./g"           =  "http://a/b/c/g"
      "g/"            =  "http://a/b/c/g/"
      "/g"            =  "http://a/g"
      "//g"           =  "http://g"
«««      "?y"            =  "http://a/b/c/d;p?y"
      "g?y"           =  "http://a/b/c/g?y"
      "#s"            =  "http://a/b/c/d;p?q#s"
      "g#s"           =  "http://a/b/c/g#s"
      "g?y#s"         =  "http://a/b/c/g?y#s"
      ";x"            =  "http://a/b/c/;x"
      "g;x"           =  "http://a/b/c/g;x"
      "g;x?y#s"       =  "http://a/b/c/g;x?y#s"
«««we have special empty String handling, URI does not treat that case correctly 
      ""              =  "http://a/b/c/d;p?q"
      "."             =  "http://a/b/c/"
      "./"            =  "http://a/b/c/"
      ".."            =  "http://a/b/"
      "../"           =  "http://a/b/"
      "../g"          =  "http://a/b/g"
      "../.."         =  "http://a/"
      "../../"        =  "http://a/"
      "../../g"       =  "http://a/g"
«««5.4.2.  Abnormal Examples
«««      "../../../g"    =  "http://a/g"
«««      "../../../../g" =  "http://a/g"
«««      "/./g"          =  "http://a/g"
«««      "/../g"         =  "http://a/g"
      "g."            =  "http://a/b/c/g."
      ".g"            =  "http://a/b/c/.g"
      "g.."           =  "http://a/b/c/g.."
      "..g"           =  "http://a/b/c/..g"
      "./../g"        =  "http://a/b/g"
      "./g/."         =  "http://a/b/c/g/"
      "g/./h"         =  "http://a/b/c/g/h"
      "g/../h"        =  "http://a/b/c/h"
      "g;x=1/./y"     =  "http://a/b/c/g;x=1/y"
      "g;x=1/../y"    =  "http://a/b/c/y"
      "g?y/./x"       =  "http://a/b/c/g?y/./x"
      "g?y/../x"      =  "http://a/b/c/g?y/../x"
      "g#s/./x"       =  "http://a/b/c/g#s/./x"
      "g#s/../x"      =  "http://a/b/c/g#s/../x"
      "http:g"        =  "http:g"
	'''

	@Test
	def void rfc3986() {
		uri=new PrefixURI(URI::createURI("http://a/b/c/d;p?q"))
		examples.split("\n").forEach[
			val split=it.replaceAll("\"","").split(" = ")
			val rel=split.get(0).trim
			val exp=split.get(1).trim
			checkResolution(rel,exp)
		]
	}

	@Test
	def void testLocalNameAgainstEmptyFragment(){
		uri=new PrefixURI(URI::createURI("http://a/b/c#"))
		checkLocalName("", "http://a/b/c#")
		checkLocalName("a", "http://a/b/c#a")
		checkLocalName("#a", "http://a/b/c##a")
		checkLocalName("x#a", "http://a/b/c#x#a")
		checkLocalName("x:a", "http://a/b/c#x:a")
	}

	@Test
	def void testLocalNameAgainstNonEmptyFragment(){
		uri=new PrefixURI(URI::createURI("http://a/b/c#x"))
		checkLocalName("", "http://a/b/c#x")
		checkLocalName("a", "http://a/b/c#xa")
		checkLocalName("#a", "http://a/b/c#x#a")
		checkLocalName("x#a", "http://a/b/c#xx#a")
		checkLocalName("x:a", "http://a/b/c#xx:a")
	}

	@Test
	def void testLocalNameAgainstNoFragment(){
		uri=new PrefixURI(URI::createURI("http://a/b/c"))
		checkLocalName("", "http://a/b/c")
		checkLocalName("a", "http://a/b/ca")
		checkLocalName("#a", "http://a/b/c#a")
		checkLocalName("x#a", "http://a/b/cx#a")
		checkLocalName("x:a", "http://a/b/cx:a")
	}

	@Test
	def void testNoSegments(){
		uri=new PrefixURI(URI::createURI("http://www.example.de"))
		checkResolution("", "http://www.example.de")
		checkResolution("/", "http://www.example.de/")
		checkResolution("#", "http://www.example.de#")
		checkResolution("a", "http://www.example.de/a")
		checkResolution("#a", "http://www.example.de#a")
		checkResolution("a#", "http://www.example.de/a#")
		checkResolution("/a", "http://www.example.de/a")
		checkResolution("a/", "http://www.example.de/a/")
	}

	@Test
	def void testShortEmptySegment(){
		uri=new PrefixURI(URI::createURI("http://www.example.de/"))
		checkResolution("", "http://www.example.de/")
		checkResolution("/", "http://www.example.de/")
		checkResolution("#", "http://www.example.de/#")
		checkResolution("a", "http://www.example.de/a")
		checkResolution("#a", "http://www.example.de/#a")
		checkResolution("a#", "http://www.example.de/a#")
		checkResolution("/a", "http://www.example.de/a")
		checkResolution("a/", "http://www.example.de/a/")
	}

	@Test
	def void testNoSegmentsFragment(){
		uri=new PrefixURI(URI::createURI("http://www.example.de#"))
		checkResolution("", "http://www.example.de#")
		checkResolution("/", "http://www.example.de/")
		checkResolution("#", "http://www.example.de#")
		checkResolution("a", "http://www.example.de/a")
		checkResolution("#a", "http://www.example.de#a")
		checkResolution("a#", "http://www.example.de/a#")
		checkResolution("/a", "http://www.example.de/a")
		checkResolution("a/", "http://www.example.de/a/")
	}

	@Test
	def void testNonEmptySegment(){
		uri=new PrefixURI(URI::createURI("http://www.example.de/x"))
		checkResolution("", "http://www.example.de/x")
		checkResolution("/", "http://www.example.de/")
		checkResolution("#", "http://www.example.de/x#")
		checkResolution("a", "http://www.example.de/a")
		checkResolution("#a", "http://www.example.de/x#a")
		checkResolution("a#", "http://www.example.de/a#")
		checkResolution("/a", "http://www.example.de/a")
		checkResolution("a/", "http://www.example.de/a/")
	}

	@Test
	def void testNonEmptyFragment(){
		uri=new PrefixURI(URI::createURI("http://www.example.de/x#tada"))
		checkResolution("", "http://www.example.de/x#tada")
		checkResolution("/", "http://www.example.de/")
		checkResolution("#", "http://www.example.de/x#")
		checkResolution("a", "http://www.example.de/a")
		checkResolution("#a", "http://www.example.de/x#a")
		checkResolution("a#", "http://www.example.de/a#")
		checkResolution("/a", "http://www.example.de/a")
		checkResolution("a/", "http://www.example.de/a/")
	}

	@Test
	def void testLongEmptySegment(){
		uri=new PrefixURI(URI::createURI("http://a/b/c/"))
		checkResolution("", "http://a/b/c/")
		checkResolution("/", "http://a/")
		checkResolution("#", "http://a/b/c/#")
		checkResolution("a", "http://a/b/c/a")
		checkResolution("#a", "http://a/b/c/#a")
		checkResolution("a#", "http://a/b/c/a#")
		checkResolution("/a", "http://a/a")
		checkResolution("a/", "http://a/b/c/a/")
		checkResolution("../x", "http://a/b/x")
		checkResolution("x/y", "http://a/b/c/x/y")
		checkResolution("x#a", "http://a/b/c/x#a")
		checkResolution("bla#fsd:fdf", "http://a/b/c/bla#fsd:fdf")
		checkResolution("bla/fsd:fdf", "http://a/b/c/bla/fsd:fdf")
		checkResolution("file://blubs.ttl", "file://blubs.ttl")

		//both java and emf URI resolve fsf:fdf as absolute URIs due to scheme fsd
		checkResolution("fsd:fdf", "fsd:fdf")
	}

	def private void checkLocalName(String uri2ResolveAgainstBase, String expectedResolutionResult){
		val URI resolved=uri.resolveLocal(uri2ResolveAgainstBase)
		Assert::assertEquals('''error for rel uri: «uri2ResolveAgainstBase»''',expectedResolutionResult, resolved.toString)
	}

	def private void checkResolution(String uri2ResolveAgainstBase, String expectedResolutionResult){
		val URI resolved=uri.resolve(uri2ResolveAgainstBase)
		Assert::assertEquals('''error for rel uri: «uri2ResolveAgainstBase»''',expectedResolutionResult, resolved.toString)
	}

	@Test
	def void testURN(){
		#["","#","#sfdf"].forEach[
			uri= new PrefixURI(URI::createURI("urn:fiddle:ontology"+it))
			val urn="urn:fiddle:ontology"
			checkResolution(urn, urn)
			checkResolution("x","urn:x")
			checkResolution("/x","urn:/x")
			checkResolution("#x","urn:fiddle:ontology#x")
			checkResolution("x:tada","x:tada")
			checkResolution("x/tada","urn:x/tada")
		]
	}
}
