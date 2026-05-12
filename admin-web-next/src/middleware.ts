import { NextResponse } from 'next/server'
import type { NextRequest } from 'next/server'

export function middleware(request: NextRequest) {
  const { pathname } = request.nextUrl

  // Allow /landing explicitly if needed (though the matcher should handle it)
  if (pathname === '/landing') {
    return NextResponse.next()
  }

  // Redirect everything else to /landing
  return NextResponse.redirect(new URL('/landing', request.url))
}

export const config = {
  matcher: [
    /*
     * Match all request paths except for the ones starting with:
     * - api (API routes)
     * - _next/static (static files)
     * - _next/image (image optimization files)
     * - images (static images)
     * - favicon.ico (favicon file)
     * - landing (the landing page itself)
     * - any file with an extension (e.g. .png, .jpg, .svg)
     */
    '/((?!api|_next/static|_next/image|images|favicon.ico|landing|.*\\..*).*)',
  ],
}
