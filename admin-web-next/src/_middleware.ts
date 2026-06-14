import { NextResponse } from 'next/server'
import type { NextRequest } from 'next/server'

export function middleware(request: NextRequest) {
  const { pathname } = request.nextUrl

  return NextResponse.next()
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
